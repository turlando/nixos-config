{ pkgs, ... }:

{
  home.stateVersion = "25.05";
  home.username = "tancredi";
  home.homeDirectory = "/home/tancredi";

  programs.ssh.enable = true;
  programs.ssh.hosts.antigone.enable = true;
  programs.ssh.hosts.creusa.enable = true;
  programs.ssh.hosts.github.enable = true;

  programs.firefox.enable = true;
  programs.firefox.profiles.tancredi = {
    id = 0;
    isDefault = true;
  };

  programs.thunderbird.enable = true;
  programs.thunderbird.profiles.tancredi = {
    isDefault = true;
  };

  programs.mozilla-settings.enable = true;
  programs.mozilla-settings.firefox = [ "tancredi" ];
  programs.mozilla-settings.thunderbird = [ "tancredi" ];

  programs.emacs.enable = true;
  programs.emacs.package = pkgs.emacs-pgtk;
}
