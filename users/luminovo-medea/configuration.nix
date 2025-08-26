{ lib, pkgs, ... }:

{
  home.stateVersion = "25.05";
  home.username = "luminovo";
  home.homeDirectory = "/home/luminovo";

  programs.ssh.enable = true;
  programs.ssh.hosts.compiler4-luminovo.enable = true;
  programs.ssh.hosts.gitlab-luminovo.enable = true;

  programs.firefox.enable = true;
  programs.firefox.profiles.luminovo= {
    id = 0;
    isDefault = true;
  };

  programs.thunderbird.enable = true;
  programs.thunderbird.profiles.luminovo = {
    isDefault = true;
  };

  programs.mozilla-settings.enable = true;
  programs.mozilla-settings.firefox = [ "luminovo" ];
  programs.mozilla-settings.thunderbird = [ "luminovo" ];

  programs.emacs.enable = true;
  programs.emacs.package = pkgs.emacs-pgtk;

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "slack"
    ];

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
