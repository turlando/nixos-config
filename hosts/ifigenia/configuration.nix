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
        "state" = { mountPoint = config.environment.state; };
        "docker" = { mountPoint = "/var/lib/docker"; };
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

  # Enable "Silent Boot"
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
  ];

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
    source = "${config.environment.state}/NetworkManager/system-connections/";
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
    wireplumber.extraConfig."10-bluez" = {
      "monitor.bluez.properties" = {
        # The SBC-XQ codec provides better sound quality for audio listening.
        "bluez5.enable-sbc-xq" = true;
        # The mSBC codec provides slightly better sound quality in calls than
        # regular HFP/HSP.
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.headset-roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
      };
    };
  };

  xdg.portal.enable = true;

  # Allow GTK theming in KDE.
  programs.dconf.enable = true;

  hardware.graphics.enable = true;

  hardware.intelgpu = {
    loadInInitrd = true;
    vaapiDriver = "intel-media-driver";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Report devices battery status.
		    Experimental = true;
	    };
    };
  };

  services.pcscd.enable = true;
  environment.etc."pkcs11/modules/opensc-pkcs11".text = ''
    module: ${pkgs.opensc}/lib/opensc-pkcs11.so
  '';

  programs.ssh.enableAskPassword = true;

  virtualisation = {
    virtualbox.host.enable = true;
    docker = {
      enable = true;
      storageDriver = "zfs";
    };
  };

  users.extraGroups.vboxusers.members = with config.users.users;
    [ tancredi.name ];

  users.extraGroups.docker.members = with config.users.users;
    [ tancredi.name ];
}
