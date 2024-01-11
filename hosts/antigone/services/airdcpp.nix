{ config, lib, packages, ... }: 

let
  inherit (lib.containers) dataPath mkContainer;

  systemDatasets = config.storage.pools.system.datasets;
  storageDatasets = config.storage.pools.storage.datasets;
  scratchDatasets = config.storage.pools.scratch.datasets;

  httpPort = 5040;
in

{
  networking.firewall.interfaces."eth0".allowedTCPPorts = [ ];

  containers = mkContainer {
    name = "airdcpp";
    data = systemDatasets."services/airdcpp".mountPoint;
    mounts = [
      storageDatasets."music/electronic".mountPoint
    ];
    config =
      { ... }:
      {
        # FIXME: find a less hacky way to do this without relying on imports.
        imports = [
          ../../../nixos/services/airdcpp.nix
        ];

        system.stateVersion = "23.11";

        networking.firewall.allowedTCPPorts = [ httpPort ];

        services.airdcpp = {
          enable = true;
          package = packages.airdcpp;
          dataDir = dataPath;
        };
      };
  };
}
