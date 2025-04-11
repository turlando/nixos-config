{ pkgs, ... }:

{
  environment.defaults.enable = true;
  programs.emacs.package = pkgs.emacs30-nox;
}
