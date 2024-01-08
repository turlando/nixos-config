{ pkgs, ... }:

{
  programs.emacs.package = pkgs.emacs29-pgtk;

  home.packages = with pkgs; [
    firefox
    source-code-pro
    telegram-desktop
  ];
}
