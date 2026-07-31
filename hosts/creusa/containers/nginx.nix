{ flake, config, lib, ... }:
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
        # journald grants per-user journal access via POSIX ACLs
        acltype = "posixacl";
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
        # container has no access to any host resolver. resolvconf only
        # compiles dhcp-style sources, which this static container has none
        # of, and falls back to loopback; disabled, so resolv.conf is
        # generated from networking.nameservers.
        networking.resolvconf.enable = false;
        environment.etc."resolv.conf".text = ''
          nameserver 9.9.9.9
          nameserver 149.112.112.112
        '';

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

        # ACME must not gate container readiness: the host configures the
        # veth only after the container reports started (notify-ready with
        # post-start networking), so any boot job waiting on the network
        # deadlocks the whole container. The ensure service and nginx's
        # want of the order service leave the boot transaction; the
        # renewal timer fires shortly after boot instead, when the veth
        # exists, and serves the persisted certificates meanwhile.
        systemd.services."acme-dracma.us.to".wantedBy = lib.mkForce [ ];
        systemd.services.nginx.wants =
          lib.mkForce [ "acme-finished-dracma.us.to.target" ];
        # OnActiveSec, not OnBootSec or OnStartupSec: containers share the
        # kernel's clocks with the host, so the timer's activation at
        # container boot is the only usable reference point. The module's
        # AccuracySec and RandomizedDelaySec spread the actual firing over
        # the following day, which the 30-day renewal window absorbs.
        systemd.timers."acme-renew-dracma.us.to".timerConfig.OnActiveSec = "2min";

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
