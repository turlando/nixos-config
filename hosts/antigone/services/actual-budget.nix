{ self, config, lib, ... }:

let
  inherit (lib.containers) dataPath mkContainer;
in

{
  networking.firewall.interfaces.wg0.allowedTCPPorts = [
    config.containers.actual-budget.config.services.actual-server.port
  ];

  containers = mkContainer {
    name = "actual-budget";
    data = config.storage.zpools.system.datasets."services/actual-budget".mountPoint;
    config =
      { pkgs, ... }:
      {
        imports = [ self.nixosModules.actual-server ];
        system.stateVersion = "24.05";

        services.actual-server = {
          enable = true;
          package = self.packages.x86_64-linux.actual-server;
          hostname = "0.0.0.0";
          dataDir = dataPath;
        };
      };
  };
}
