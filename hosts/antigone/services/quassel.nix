{ config, lib, ... }:

let
  inherit (lib.containers) dataPath mkContainer;
in
{
  containers = mkContainer {
    name = "quassel";
    data = config.storage.pools.system.datasets."services/quassel".mountPoint;
    config =
      { pkgs, ... }:
      {
        system.stateVersion = "23.11";

        environment.systemPackages = [
          ## So that I can run:
          # nixos-container root-login quassel
          # sudo -u quassel openssl req -x509 -nodes -days 365 \
          #   -newkey rsa:4096 -keyout /data/quasselCert.pem   \
          #   -out /data/quasselCert.pem
          pkgs.openssl

          ## So that I can run:
          # nixos-container root-login quassel
          # sudo -u quassel quasselcore --configdir=/data --add-user
          pkgs.quasselDaemon
        ];

        services.quassel = {
          enable = true;
          dataDir = dataPath;
        };
      };
  };
}
