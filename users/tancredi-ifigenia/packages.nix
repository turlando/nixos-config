{ pkgs, ... }:

{
  programs.emacs.package = pkgs.emacs29-pgtk;

  programs.firefox = {
    enable = true;
    profiles.tancredi = {
      isDefault = true;
      settings = {
        "extensions.pocket.enabled" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
      };
    };
  };

  # Workaround https://github.com/nix-community/home-manager/issues/2064
	systemd.user.targets.tray = {
		Unit = {
			Description = "Home Manager System Tray";
			Requires = [ "graphical-session-pre.target" ];
		};
	};

  services.syncthing = {
    enable = true;
    tray.enable = true;
  };

  home.packages = with pkgs; [
    source-code-pro

    keepassxc

    telegram-desktop
    whatsapp-for-linux

    vlc
  ];
}
