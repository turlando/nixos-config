{
  inputs = {
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    ...
  }@inputs: {
    nixosModules = import ./nixos;
    nixosConfigurations = import ./hosts inputs;
    homeManagerModules = import ./home-manager;
    homeConfigurations = import ./users inputs;
  }
  // flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
  in {
    checks = {
      statix = pkgs.statix;
      deadnix = pkgs.deadnix;
    };
    formatter = pkgs.alejandra;
    devShells = import ./shells (inputs // { inherit pkgs system; });
  });
}
