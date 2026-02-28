{
  inputs = {
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixvirt = {
      url = "github:AshleyYakeley/NixVirt/v0.6.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    flake-utils,
    nixpkgs,
    ...
  }@inputs: {
    lib = import ./lib { inherit (nixpkgs) lib; };
    nixosModules = import ./nixos;
    nixosConfigurations = import ./hosts inputs;
    homeManagerModules = import ./home-manager;
    homeConfigurations = import ./users inputs;
  }
  // flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
  in {
    devShells = import ./shells (inputs // { inherit pkgs system; });
    checks = { tests = (import ./tests { inherit pkgs; }).run-all; };
  });
}
