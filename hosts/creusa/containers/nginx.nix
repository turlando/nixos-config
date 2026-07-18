{ flake, config, ... }:
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

  networking.firewall.interfaces.eth0.allowedTCPPorts = [
    80 443
  ];

  containers.nginx = {
    ephemeral = true;
    autoStart = true;
    extraFlags = [ "--resolv-conf=bind-host" ];

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
                  actualCfg = hostConfig.containers.actual-budget.config.services.actual;
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
