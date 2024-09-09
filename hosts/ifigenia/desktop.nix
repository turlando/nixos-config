{ config, pkgs, ... }:

{
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
