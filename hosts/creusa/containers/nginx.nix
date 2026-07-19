{ flake, config, ... }:
let
  # Private network namespace addressing: the container's veth peers with
  # creusa's shared services-side address.
  nginxAddress = config.environment.network.hosts.creusa-nginx.interfaces.svc0.address;
  servicesGateway = config.environment.network.hosts.creusa.interfaces.svc0.address;
in
{
  disko.devices.zpool.creusa.datasets = {
    "containers/nginx" = {
      type = "zfs_fs";
      options = {
        canmount = "off";
      };
    };

    "containers/nginx/journal" = {
      type = "zfs_fs";
      mountpoint = "/var/containers/nginx/journal";
      options = {
        recordsize = "16K";
        primarycache = "metadata";
        sync = "disabled";
        atime = "off";
      };
    };

    "containers/nginx/logs" = {
      type = "zfs_fs";
      mountpoint = "/var/containers/nginx/logs";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.environment.persistence.stateDir}/var/lib/acme 0750 root root -"
  ];

  # The public web ports DNAT into the container (the forward chain accepts
  # DNAT'd flows); nginx alone gets masqueraded egress, for ACME and OCSP,
  # and in turn reaches only the actual container.
  networking.nat.forwardPorts = [
    {
      sourcePort = 80;
      proto = "tcp";
      destination = "${nginxAddress}:80";
    }
    {
      sourcePort = 443;
      proto = "tcp";
      destination = "${nginxAddress}:443";
    }
  ];
  networking.nat.internalIPs = [ "${nginxAddress}/32" ];
  networking.firewall.extraForwardRules = ''
    iifname "ve-nginx" oifname "ve-actual" accept
  '';

  containers.nginx = {
    ephemeral = true;
    autoStart = true;

    # Own network namespace: the container sees only its veth. nspawn's
    # resolv.conf handling is off, as it would bind the host's; the
    # container writes its own.
    privateNetwork = true;
    hostAddress = servicesGateway;
    localAddress = nginxAddress;
    extraFlags = [ "--resolv-conf=off" ];

    bindMounts = {
      "/var/log/journal" = {
        hostPath = config.disko.devices.zpool.creusa.datasets
          ."containers/nginx/journal".mountpoint;
        isReadOnly = false;
      };

      "/var/log/nginx" = {
        hostPath = config.disko.devices.zpool.creusa.datasets
          ."containers/nginx/logs".mountpoint;
        isReadOnly = false;
      };

      "/var/lib/acme" = {
        hostPath = "${config.environment.persistence.stateDir}/var/lib/acme";
        isReadOnly = false;
      };
    };

    config = let
      hostConfig = config;
    in
      { ... }:
      {
        imports = [
          flake.nixosModules.modules.services.journald
        ];

        system.stateVersion = "26.05";
        environment.etc."machine-id".text = "a57b69a7ef72b1aa85c104a969af4c02";
        # Public resolver: ACME ordering and OCSP need to resolve, and the
        # container has no access to any host resolver.
        networking.nameservers = [ "9.9.9.9" "149.112.112.112" ];

        # The namespace's own firewall: the DNAT'd public web ports.
        networking.firewall.allowedTCPPorts = [ 80 443 ];

        services.journald.settings = {
          SystemMaxUse = "256M";
          SystemMaxFileSize = "32M";
          MaxRetentionSec = "1month";
        };

        security.acme = {
          acceptTerms = true;
          defaults = {
            email = "turlando@gmail.com";
            inherit (config.services.nginx) group;
          };
        };

        services.nginx = {
          enable = true;
          recommendedProxySettings = true;

          virtualHosts = {
            ${hostConfig.environment.network.dns.records.dracma.name} = {
              enableACME = true;
              forceSSL = true;

              locations."/".proxyPass =
                let
                  actualCfg = hostConfig.containers.actual.config.services.actual;
                  inherit (actualCfg.settings) hostname port;
                in
                  "http://${hostname}:${toString port}";

              extraConfig = ''
                error_log /var/log/nginx/${hostConfig.environment.network.dns.records.dracma.name}-error.log error;
                access_log /var/log/nginx/${hostConfig.environment.network.dns.records.dracma.name}-access.log combined;
              '';
            };
          };
        };
      };
  };
}
