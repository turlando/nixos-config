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
        proxyPass = let
          actualCfg = config.containers.
            "actual-budget-${name}"
            .config.services.actual-server;
          host = actualCfg.hostname;
          port = toString actualCfg.port;
        in "http://${host}:${port}";
        recommendedProxySettings = true;
      };
    };
  };
in

{
  networking.firewall.interfaces.eth0.allowedTCPPorts = [ 80 443 ];

  containers = mkContainer {
    name = "nginx";
    data = systemDatasets."services/nginx".mountPoint;
    config =
      { ... }:
      {
        system.stateVersion = "24.05";

        fileSystems."/var/lib/acme" = {
          device = "${dataPath}/acme";
          options = [ "bind" ];
        };

        security.acme = {
          acceptTerms = true;
          defaults = {
            email = "turlando@gmail.com";
            group = config.services.nginx.group;
            webroot = "/var/lib/acme/acme-challenge";
          };
        };

        services.nginx = {
          enable = true;

          virtualHosts = mkMerge [
            ( mkActualProxy { name = "tancredi"; hostName = "dracma.us.to"; })
          ];
        };
      };
  };
}
