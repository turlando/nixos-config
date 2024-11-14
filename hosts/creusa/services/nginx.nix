{ config, lib, ... }:

let
  inherit (lib.containers) dataPath mkContainer;
  systemDatasets = config.storage.zpools.system.datasets;
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
          virtualHosts = {
            "dracma.us.to" = {
              enableACME = true;
              forceSSL = true;
              locations."/" = {
                proxyPass = let
                  actualCfg = config.containers.actual-budget.config.services.actual-server;
                in
                  "http://${actualCfg.hostname}:${toString actualCfg.port}";
                recommendedProxySettings = true;
              };
            };
          };
        };
      };
  };
}
