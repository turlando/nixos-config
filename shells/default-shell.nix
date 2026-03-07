{ system, pkgs, pkgs-unstable, agenix, disko, home-manager, ... }:

let
  agenix-pkgs = agenix.packages.${system};
  disko-pkgs = disko.packages.${system};
  home-manager-pkgs = home-manager.packages.${system};
in pkgs.mkShell {
  packages = [
    pkgs.deadnix
    pkgs.just
    pkgs.nixd
    pkgs.statix
    (pkgs-unstable.opentofu.withPlugins (p: [ p.hetznercloud_hcloud ]))
    agenix-pkgs.default
    disko-pkgs.default
    home-manager-pkgs.default
  ];
}
