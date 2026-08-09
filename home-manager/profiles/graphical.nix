{ config, pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  fonts.families.monospace = {
    family = "Aporetic Sans Mono";
    size = 10.5;
    package = pkgs.aporetic;
  };

  fonts.families.sansSerif = {
    family = "Noto Sans";
    size = 10;
    package = pkgs.noto-fonts;
  };

  fonts.families.serif = {
    family = "Noto Serif";
    size = 10;
    package = pkgs.noto-fonts;
  };

  # Enable Bluetooth headsets buttons support.
  services.mpris-proxy.enable = true;

  programs.ghostty = {
    enable = true;
    settings = {
      theme = "Breeze";
      font-family = config.fonts.families.monospace.family;
      font-size = config.fonts.families.monospace.size;
      window-decoration = "server";
      window-theme = "system";
      window-width = 140;
      window-height = 40;
      background-blur = true;
      mouse-hide-while-typing = true;
      gtk-custom-css = toString (pkgs.writeText "ghostty.css" ''
        tabbar tabbox { min-height: 0; margin: 0; padding: 2px; }
        tabbar tabbox tab { min-height: 16px; padding: 2px 8px; }
      '');
    };
  };

  # Workaround for GTK 4.20 dropping the built-in compose/dead-key fallback
  # on Wayland with no IM module. The declarative path is
  # gtk.gtk4.extraConfig.gtk-im-module, but enabling the HM gtk module
  # conflicts with kde-gtk-config writing the same settings.ini at runtime.
  # Migrate when moving to plasma-manager and dropping kde-gtk-config.
  systemd.user.sessionVariables.GTK_IM_MODULE = "simple";

  programs.keepassxc.enable = true;

  home.packages = [
    # KDE's mpv frontend: Qt6/Breeze native, MPRIS aware, VAAPI decoding.
    pkgs.haruna

    pkgs.libreoffice-qt6-fresh
    pkgs.hunspell
    pkgs.hunspellDicts.en-us
    pkgs.hunspellDicts.it-it
  ];
}
