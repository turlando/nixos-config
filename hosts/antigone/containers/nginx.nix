{ self, config, ... }:
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

  containers.nginx = {
    ephemeral = true;
    autoStart = true;
    extraFlags = [ "--resolv-conf=bind-host" ];

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
          self.nixosModules.modules.services.journald
        ];

        system.stateVersion = "26.05";
        environment.etc."machine-id".text = "c0fdad4607d74823ab6e7c26fb178df9";

        services.journald.settings = {
          SystemMaxUse = "256M";
          SystemMaxFileSize = "32M";
          MaxRetentionSec = "1month";
        };

        # HTTP only for now (the LAN is trusted); TLS arrives with ACME later.
        # Containers share the host network namespace, so slskd's web port is
        # reachable over loopback.
        services.nginx = {
          enable = true;
          recommendedProxySettings = true;

          virtualHosts."slskd.antigone.perosi.rhyzomatic.net" = {
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
        };
      };
  };
}
