{ self, config, lib, ... }: 

let
  inherit (lib.containers) dataPath mkContainer;

  systemDatasets = config.storage.zpools.system.datasets;
  storageDatasets = config.storage.zpools.storage.datasets;
  scratchDatasets = config.storage.zpools.scratch.datasets;

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
        imports = [ self.nixosModules.slskd ];

        system.stateVersion = "23.11";

        networking.firewall.allowedTCPPorts = [ soulseekNetPort httpPort ];

        services.slskd = {
          enable = true;
          package = self.packages.x86_64-linux.slskd;
          rotateLogs = true;
          dataDir = dataPath;
          configFile = "${dataPath}/slskd.yml";
        };
      };
  };
}
