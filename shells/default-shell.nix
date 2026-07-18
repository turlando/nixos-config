{ flake, system, pkgs, pkgs-unstable }:

let
  agenix-pkgs = flake.inputs.agenix.packages.${system};
  disko-pkgs = flake.inputs.disko.packages.${system};
  home-manager-pkgs = flake.inputs.home-manager.packages.${system};
  nix-unit-pkgs = flake.inputs.nix-unit.packages.${system};
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
    nix-unit-pkgs.default
  ];
}
