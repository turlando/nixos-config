{ config, pkgs, ... }:

{
  home.stateVersion = "26.05";
  home.username = "luminovo";
  home.homeDirectory = "/home/luminovo";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "gitlab.com" = {
        HostName = "gitlab.com";
        User = "git";
        IdentityFile = config.age.secrets.ssh-key-luminovo-gitlab.path;
      };
      "compiler4.luminovo.com" = {
        HostName = "148.251.132.243";
        User = "tancredi";
        IdentityFile = config.age.secrets.ssh-key-luminovo-compilers.path;
      };
    };
  };

  programs.firefox.enable = true;
  programs.firefox.profiles.luminovo = {
    id = 0;
    isDefault = true;
    enableCustomDefaults = true;
  };

  programs.thunderbird.enable = true;
  programs.thunderbird.profiles.luminovo = {
    isDefault = true;
    enableCustomDefaults = true;
  };

  programs.emacs.enable = true;
  programs.emacs.package = pkgs.emacs-pgtk;

  home.packages = [
    pkgs.slack

    pkgs.just

    pkgs.git
    pkgs.git-lfs

    pkgs.azure-cli
    pkgs.kubectl
    pkgs.fluxcd
    pkgs.k9s

    pkgs.dbeaver-bin
  ];
}
