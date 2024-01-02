{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: let 
    lib = nixpkgs.lib.extend (final: prev: import ./lib prev);
  in {
    packages = {
      "x86_64-linux" = import ./pkgs nixpkgs.legacyPackages."x86_64-linux";
    };

    nixosConfigurations = {
      antigone  = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit lib;
          packages = self.packages."x86_64-linux";
        };
        modules = [
          ./nixos
          ./hosts/common
          ./hosts/antigone
        ];
      };
    };

    homeConfigurations = {
      "tancredi@antigone" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        modules = [
          ./users/tancredi-common
          ./users/tancredi-antigone
        ];
      };
    };
  };
}
