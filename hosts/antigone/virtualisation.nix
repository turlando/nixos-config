{ config, pkgs, ... }:

{
  virtualisation = {
    podman = {
      enable = true;
      extraPackages = [ pkgs.zfs ];
    };
    
    containers.storage.settings.storage = {
      driver = "zfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";

      options.zfs = {
        fsname = config.storage.zpools.system.datasets.podman.name;
      };
    };
  };
}
