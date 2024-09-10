{ config, pkgs, ... }:

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
        "home" = { mountPoint = null; };
        "home/tancredi" = { mountPoint = "/home/tancredi"; };
        "swap" = { mountPoint = null; };
      };
    };
  };

  swapDevices = [
    { device = "/dev/zvol/system/swap"; }
  ];

  services.ephemeral = {
    enable = true;
    datasets = {
      "${config.storage.zpools.system.datasets.root.name}" = { enable = true; };
    };
  };

  boot.plymouth.enable = true;

  boot.supportedFilesystems = [ "ntfs" ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  services.logind.lidSwitch = "lock";

  networking.hostName = "ifigenia";
  networking.hostId = "a8c08001"; # Required by ZFS

  networking.interfaces = {
    eth0 = { macAddress = "50:7b:9d:02:13:03"; };
    wlan0 = { macAddress = "4c:34:88:24:ff:13"; };
  };

  networking.networkmanager.enable = true;

  environment.etc."NetworkManager/system-connections" = {
    source = "${toString config.environment.state}/NetworkManager/system-connections/";
  };

  environment.defaults.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "plasma";

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  xdg.portal.enable = true;

  # Allow GTK theming in KDE.
  programs.dconf.enable = true;

  # VirtualBox
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = with config.users.users;
    [ tancredi.name ];

  environment.systemPackages = with pkgs; [ kio-fuse ];
}
