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
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-unit = {
      url = "github:nix-community/nix-unit";
      # Follows nixpkgs-unstable (not nixpkgs) because nix-unit needs
      # pkgs.nixVersions.nixComponents_2_34, which is unstable-only.
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

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
    self,
    flake-utils,
    nixpkgs,
    nixpkgs-unstable,
    ...
  }: {
    lib = import ./lib { inherit (nixpkgs) lib; };
    nixosModules = import ./nixos;
    nixosConfigurations = import ./hosts self;
    homeManagerModules = import ./home-manager;
    homeConfigurations = import ./users self;
    tests = import ./tests { inherit (nixpkgs) lib; };
  }
  // flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
    pkgs-unstable = import nixpkgs-unstable { inherit system; };
    args = { flake = self; inherit system pkgs pkgs-unstable; };
  in {
    inherit (import ./scripts args) apps;
    devShells = import ./shells args;
    packages = (import ./packages args) // {
      terraform-config = import ./infra args;
    };
  });
}
