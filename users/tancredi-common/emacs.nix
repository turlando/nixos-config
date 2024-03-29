{ lib, pkgs, ... }:

let
  inherit (lib.files) getFile;
in
{
  programs.emacs.enable = true;

  services.emacs.enable = true;
  services.emacs.client.enable = true;

  home.file.".emacs.d" = { source = getFile /emacs.d; recursive = true; };
}
