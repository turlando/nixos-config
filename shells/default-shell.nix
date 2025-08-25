{ pkgs, agenix, disko, home-manager, system, ... }:

let
  agenix-pkgs = agenix.packages.${system};
  disko-pkgs = disko.packages.${system};
  home-manager-pkgs = home-manager.packages.${system};
in pkgs.mkShell {
  packages = [
    pkgs.just
    agenix-pkgs.default
    disko-pkgs.default
    home-manager-pkgs.default
  ];
}
