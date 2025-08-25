{ pkgs, ... }:

{
  boot.silent.enable = true;
  boot.plymouth.enable = true;

  networking.networkmanager.enable = true;

  services.avahi.enable = true;
  services.printing.enable = true;
  services.printing.webInterface = false;

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

  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings.General.Experimental = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  services.desktopManager.plasma6.enable = true;
  programs.dconf.enable = true;
  environment.plasma6.excludePackages = [
    # Comment out this line if you use KDE Connect
    pkgs.kdePackages.plasma-browser-integration
    # Unneeded if you use Thunderbird, etc.
    pkgs.kdePackages.kdepim-runtime
  ];

  environment.persistence.paths = [
    "/etc/NetworkManager/system-connections"
    "/var/lib/cups"
    "/var/lib/bluetooth"
  ];
}
