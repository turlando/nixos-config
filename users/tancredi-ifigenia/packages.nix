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
      };
    };
  };

  home.packages = with pkgs; [
    source-code-pro

    telegram-desktop
    keepassxc
  ];
}
