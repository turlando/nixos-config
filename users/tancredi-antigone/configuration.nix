{ pkgs, ... }:

{
  environment.defaults.enable = true;
  programs.emacs.package = pkgs.emacs29-nox;
}
