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

    nix-unit = {
      url = "github:nix-community/nix-unit";
      # Follows nixpkgs-unstable (not nixpkgs) because nix-unit needs
      # pkgs.nixVersions.nixComponents_2_34, which is unstable-only.
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixvirt = {
      url = "github:AshleyYakeley/NixVirt/v0.6.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    flake-utils,
    nixpkgs,
    nixpkgs-unstable,
    ...
  }@inputs: {
    lib = import ./lib { inherit (nixpkgs) lib; };
    nixosModules = import ./nixos;
    nixosConfigurations = import ./hosts inputs;
    homeManagerModules = import ./home-manager;
    homeConfigurations = import ./users inputs;
    tests = import ./tests { inherit (nixpkgs) lib; };
  }
  // flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
    pkgs-unstable = import nixpkgs-unstable { inherit system; };
  in {
    inherit (import ./scripts (inputs // { inherit system pkgs pkgs-unstable; })) apps;
    devShells = import ./shells (inputs // { inherit system pkgs pkgs-unstable; });
    packages = {
      terraform-config = import ./infra (inputs // { inherit system; });
    };
  });
}
