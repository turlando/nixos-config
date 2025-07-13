{ self, config, lib, pkgs-unstable, ... }:

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
          imports = [ self.nixosModules.actual ];
          system.stateVersion = "25.05";
          networking.hostName = "actual-budget-${name}";
          services.actual  = {
            enable = true;
            package = pkgs-unstable.actual-server;
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
