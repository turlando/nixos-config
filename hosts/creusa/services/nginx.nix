{ config, lib, ... }:

let
  inherit (lib.modules) mkMerge;
  inherit (lib.containers) dataPath mkContainer;

  systemDatasets = config.storage.zpools.system.datasets;

  mkActualProxy = { name, hostName }: {
    "${hostName}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyPass = let
          actualCfg = config.containers.
            "actual-budget-${name}"
            .config.services.actual;
          host = actualCfg.hostname;
          port = toString actualCfg.port;
        in "http://${host}:${port}";
      };
    };
  };
in

{
  networking.firewall.interfaces.eth0.allowedTCPPorts = [ 80 443 ];

  containers = mkContainer {
    name = "nginx";
    mounts = [
      "${config.environment.state}/var/lib/acme"
    ];
    config =
      { ... }:
      {
        system.stateVersion = "24.11";

        fileSystems."/var/lib/acme" = {
          device = "${config.environment.state}/var/lib/acme";
          options = [ "bind" ];
        };

        security.acme = {
          acceptTerms = true;
          defaults = {
            email = "turlando@gmail.com";
            group = config.services.nginx.group;
            webroot = "/tmp";
          };
        };

        services.nginx = {
          enable = true;
          virtualHosts = mkMerge [
            (mkActualProxy { name = "tancredi"; hostName = "dracma.us.to"; })
            (mkActualProxy { name = "savasta-bianca"; hostName = "entrapta.us.to"; })
          ];
        };
      };
  };
}
