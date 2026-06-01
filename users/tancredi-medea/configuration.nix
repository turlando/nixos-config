{ config, pkgs, ... }:

{
  home.stateVersion = "26.05";
  home.username = "tancredi";
  home.homeDirectory = "/home/tancredi";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "antigone" = {
        HostName = "81.56.74.151";
        Port = 13022;
        User = "tancredi";
        IdentityFile = config.age.secrets.ssh-key-antigone-tancredi.path;
      };
      "creusa" = {
        HostName = "46.225.229.141";
        User = "root";
        IdentityFile = config.age.secrets.ssh-key-creusa-root.path;
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = config.age.secrets.ssh-key-github.path;
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
