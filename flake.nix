{
  description = "NixOS configuration";

  nixConfig = {
    extra-trusted-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-substituers-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" 
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: let 
    system = "x86_64-linux";
    lib = nixpkgs.lib.extend (final: prev: import ./lib prev);
    overlays = with inputs; [ emacs-overlay.overlays.default ];
  in {
    packages = {
      "${system}" = import ./pkgs (import nixpkgs { inherit system; });
    };

    nixosConfigurations = {
      antigone  = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit lib;
          packages = self.packages."${system}";
        };
        modules = [
          ({ ... }: { nixpkgs.overlays = overlays; })
          ./nixos
          ./hosts/common
          ./hosts/antigone
        ];
      };
    };

    homeConfigurations = {
      "tancredi@antigone" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; inherit overlays; };
        modules = [
          ./users/tancredi-common
          ./users/tancredi-antigone
        ];
      };
    };
  };
}
