{ config, lib, ... }: 

let
  inherit (lib.containers) dataPath mkContainer;

  systemDatasets = config.storage.pools.system.datasets;
  storageDatasets = config.storage.pools.storage.datasets;
  scratchDatasets = config.storage.pools.scratch.datasets;

  soulseekNetPort = 23530;
  httpPort = 5030;
in

{
  networking.firewall.interfaces."eth0".allowedTCPPorts = [ soulseekNetPort ];

  containers = mkContainer {
    name = "slskd";
    data = systemDatasets."services/slskd".mountPoint;
    mounts = [
      storageDatasets."music/electronic".mountPoint
      scratchDatasets."downloads/slskd".mountPoint
    ];
    config =
      { ... }:
      {
        # FIXME: find a less hacky way to do this without relying on imports.
        imports = [
          ../../../nixos/services/slskd.nix
        ];

        system.stateVersion = "23.11";

        networking.firewall.allowedTCPPorts = [ soulseekNetPort httpPort ];

        services.slskd = {
          enable = true;
          rotateLogs = true;
          dataDir = dataPath;
          configFile = "${dataPath}/slskd.yml";
        };
      };
  };
}
