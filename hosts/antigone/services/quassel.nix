{ config, lib, ... }:

let
  inherit (lib.attrsets) mergeAttrsets;
  inherit (lib.filesystems) serviceFileSystem servicePath;

  name = "quassel";
  data = config.storage.pools.system.datasets."services/${name}".mountPoint;
  dataPath = "/data";
in
{
  containers."${name}" = {
    ephemeral = true;
    autoStart = true;

    bindMounts = {
      "${dataPath}" = {
        hostPath = dataPath;
        isReadOnly = false;
      };
    };

    # See https://github.com/NixOS/nixpkgs/issues/196370
    extraFlags = [
      "--resolv-conf=bind-host"
    ];

    config =
      { config, pkgs, ... }:
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
