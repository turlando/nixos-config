{ self, config, lib, ... }:

let
  inherit (lib.modules) mkMerge;
  inherit (lib.containers) dataPath mkContainer;

  mkActualContainer = { name, port }:
    mkContainer {
      name = "actual-budget-${name}";
      data = config.storage.zpools.system.datasets.
        "services/actual-budget/${name}"
        .mountPoint;
      config =
        { pkgs, ... }:
        {
          imports = [ self.nixosModules.actual-server ];
          system.stateVersion = "24.11";
          networking.hostName = "actual-budget-${name}";
          services.actual-server = {
            enable = true;
            package = self.packages.aarch64-linux.actual-server;
            dataDir = dataPath;
            port = port;
          };
        };
    };
in

{
  containers = mkMerge [
    (mkActualContainer { name = "tancredi"; port = 5100; })
    (mkActualContainer { name = "savasta-bianca"; port = 5101; })
  ];
}
