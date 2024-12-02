{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    home-manager,
    flake-utils,
    ...
  }@inputs:
  let
    eachSystem = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems;
    lib = nixpkgs.lib.extend (final: prev: import ./lib prev);
  in
  {
    packages = eachSystem (s: import ./pkgs nixpkgs.legacyPackages.${s});
    nixosModules = import ./nixos;
    nixosConfigurations = import ./hosts (inputs // { inherit lib; });
    homeManagerModules = import ./home-manager;
    homeConfigurations = import ./users (inputs // { inherit lib; });
    devShells = eachSystem (s: { default = import ./shell.nix nixpkgs.legacyPackages.${s}; });
  };
}
