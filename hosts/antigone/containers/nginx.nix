{ flake, config, ... }:
let
  # Private network namespace addressing: the container's veth peers with
  # antigone's shared services-side address.
  nginxAddress = config.environment.network.hosts.antigone-nginx.interfaces.svc0.address;
  servicesGateway = config.environment.network.hosts.antigone.interfaces.svc0.address;
in
{
  disko.devices.zpool.antigone.datasets = {
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

  # The service UIs' DNS records answer with this container's address; LAN
  # and VPN clients route to it through antigone, and nginx in turn reaches
  # only the two backend UIs.
  networking.firewall.extraForwardRules = ''
    iifname { "lan0", "wg0" } oifname "ve-nginx" tcp dport 80 accept
    iifname "ve-nginx" oifname { "ve-slskd", "ve-syncthing" } accept
  '';

  containers.nginx = {
    ephemeral = true;
    autoStart = true;

    # Own network namespace: the container sees only its veth. No
    # resolv.conf at all: nginx gets no internet egress and proxies by
    # address.
    privateNetwork = true;
    hostAddress = servicesGateway;
    localAddress = nginxAddress;
    extraFlags = [ "--resolv-conf=off" ];

    bindMounts = {
      "/var/log/journal" = {
        hostPath = config.disko.devices.zpool.antigone.datasets
          ."containers/nginx/journal".mountpoint;
        isReadOnly = false;
      };

      "/var/log/nginx" = {
        hostPath = config.disko.devices.zpool.antigone.datasets
          ."containers/nginx/logs".mountpoint;
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
        environment.etc."machine-id".text = "c0fdad4607d74823ab6e7c26fb178df9";
        # No resolver: nginx has no egress and proxies by address. With
        # resolvconf's loopback fallback disabled, resolv.conf is empty
        # rather than pointing at a resolver that does not exist.
        networking.resolvconf.enable = false;

        # The namespace's own firewall: HTTP from the routed clients.
        networking.firewall.allowedTCPPorts = [ 80 ];

        services.journald.settings = {
          SystemMaxUse = "256M";
          SystemMaxFileSize = "32M";
          MaxRetentionSec = "1month";
        };

        # HTTP only for now (the LAN is trusted); TLS arrives with ACME later.
        # The backend UIs bind their containers' veths; antigone forwards
        # nginx's traffic to them.
        services.nginx = {
          enable = true;
          recommendedProxySettings = true;

          virtualHosts.${hostConfig.environment.network.dns.records.slskd.name} = {
            locations."/" = {
              proxyPass =
                let
                  slskdCfg = hostConfig.containers.slskd.config.services.slskd;
                  inherit (slskdCfg.settings.web) ip_address port;
                in
                  "http://${ip_address}:${toString port}";
              proxyWebsockets = true;
            };

            extraConfig = ''
              error_log /var/log/nginx/slskd-error.log error;
              access_log /var/log/nginx/slskd-access.log combined;
            '';
          };

          virtualHosts.${hostConfig.environment.network.dns.records.syncthing.name} = {
            locations."/" = {
              proxyPass = "http://${hostConfig.containers.syncthing.config.services.syncthing.guiAddress}";
              proxyWebsockets = true;
            };

            extraConfig = ''
              error_log /var/log/nginx/syncthing-error.log error;
              access_log /var/log/nginx/syncthing-access.log combined;
            '';
          };
        };
      };
  };
}
