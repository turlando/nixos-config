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
        HostName = "10.241.23.1";
        User = "root";
        IdentityFile = config.age.secrets.ssh-key_antigone-root_medea-tancredi.path;
      };
      "antigone-unlock" = {
        HostName = "10.241.23.1";
        Port = 2222;
        User = "root";
        IdentityFile = config.age.secrets.ssh-key_antigone-root_medea-tancredi.path;
      };
      "creusa" = {
        HostName = "46.225.229.141";
        User = "root";
        IdentityFile = config.age.secrets.ssh-key_creusa-root_medea-tancredi.path;
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = config.age.secrets.ssh-key_github-git_medea-tancredi.path;
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
