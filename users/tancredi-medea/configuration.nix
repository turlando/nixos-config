{ config, pkgs, ... }:

{
  home.stateVersion = "25.11";
  home.username = "tancredi";
  home.homeDirectory = "/home/tancredi";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "antigone" = {
        hostname = "81.56.74.151";
        port = 13022;
        user = "tancredi";
        identityFile = config.age.secrets.ssh-key-antigone-tancredi.path;
      };
      "creusa" = {
        hostname = "46.225.229.141";
        user = "root";
        identityFile = config.age.secrets.ssh-key-creusa-root.path;
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = config.age.secrets.ssh-key-github.path;
      };
    };
  };

  programs.firefox.enable = true;
  programs.firefox.enableSmartCardSupport = true;
  programs.firefox.profiles.tancredi = {
    id = 0;
    isDefault = true;
    enableCustomDefaults = true;
  };

  programs.thunderbird.enable = true;
  programs.thunderbird.profiles.tancredi = {
    isDefault = true;
    enableCustomDefaults = true;
  };

  programs.emacs.enable = true;
  programs.emacs.package = pkgs.emacs-pgtk;

  home.packages = [
    pkgs.kdePackages.krdc
  ];
}
