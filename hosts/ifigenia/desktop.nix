{ config, ... }:

{
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.displayManager.defaultSession = "plasmawayland";

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Allow GTK theming in KDE.
  programs.dconf.enable = true;

  # VirtualBox
   virtualisation.virtualbox.host.enable = true;
   users.extraGroups.vboxusers.members = with config.users.users;
     [ tancredi.name ];
}
