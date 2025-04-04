{ pkgs, ... }:

{
  environment.defaults.enable = true;

  # Enable Bluetooth headsets buttons support.
  services.mpris-proxy.enable = true;

  programs.emacs.package = pkgs.emacs-pgtk;

  programs.firefox = {
    enable = true;
    policies = {
      # Smartcard support
      SecurityDevices.p11-kit-proxy = "${pkgs.p11-kit}/lib/p11-kit-proxy.so";
    };
    profiles = let
      settings = {
        "extensions.pocket.enabled" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
      };
    in {
      tancredi = {
        id = 0;
        isDefault = true;
        inherit settings;
      };
      google = {
        id = 1;
        inherit settings;
      };
      unime = {
        id = 2;
        inherit settings;
      };
    };
  };

  programs.thunderbird = {
    enable = true;
    profiles = {
      tancredi = {
        isDefault = true;
        settings = {
          "widget.use-xdg-desktop-portal.file-picker" = 1;
        };
      };
    };
  };

  # See https://github.com/nix-community/home-manager/issues/2064
  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };

  services.syncthing = {
    enable = true;
    tray.enable = true;
    tray.command = "syncthingtray --wait";
  };

  home.packages = with pkgs; [
    podman

    sshfs

    source-code-pro

    keepassxc

    telegram-desktop
    whatsapp-for-linux
    quasselClient

    vlc
    quodlibet-full

    libreoffice-qt

    hunspell
    hunspellDicts.en-us
    hunspellDicts.it-it
  ];
}
