{ config, ... }:

{
  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-partlabel/efi";
      fsType = "vfat";
      options = [ "nofail" ];
    };
  };

  storage.zpools = {
    system = {
      datasets = {
        "root" = { mountPoint = "/"; };
        "nix" = { mountPoint = "/nix"; };
        "state" = { mountPoint = "/var/state"; };
        "services" = { mountPoint = null; };
        "services/actual-budget" = { mountPoint = null; };
        "services/actual-budget/tancredi" = {
          mountPoint = "/var/services/actual-budget/tancredi";
        };
        "services/nginx" = { mountPoint = "/var/services/nginx"; };
        "home" = { mountPoint = null; };
        "home/tancredi" = { mountPoint = "/home/tancredi"; };
      };
    };
  };

  services.ephemeral = {
    enable = true;
    datasets = {
      "${config.storage.zpools.system.datasets.root.name}" = { enable = true; };
    };
  };

  networking.interfaces = {
    eth0 = { macAddress = "96:00:03:d9:60:db"; };
  };

  networking.hostName = "creusa";
  networking.hostId = "98d6fb69"; # Required by ZFS

  environment.defaults.enable = true;

  services.zfs.autoScrub = {
    enable = true;
    # Run on the first Monday of every month at 02:00.
    interval = "Mon *-*-1..7 02:00:00";
  };

  services.zfs.trim = {
    enable = true;
    # Run on every Friday at 02:00.
    interval = "Fri *-*-* 02:00:00";
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
