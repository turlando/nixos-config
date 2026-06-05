{ pkgs, ... }:

{
  minimal-emacs-d = pkgs.callPackage ./minimal-emacs-d { };
}
