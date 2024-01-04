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
    system = "x86_64-linux";
    lib = nixpkgs.lib.extend (final: prev: import ./lib prev);
    pkgs = nixpkgs.legacyPackages."${system}";
    packages = self.packages."${system}";
  in {
    packages = {
      "${system}" = import ./pkgs pkgs;
    };

    nixosConfigurations = {
      antigone  = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit lib;
          inherit packages;
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
        inherit pkgs;
        extraSpecialArgs = {
          inherit packages;
          lib = lib.extend (_: _: home-manager.lib);
        };
        modules = [
          ./users/tancredi-common
          ./users/tancredi-antigone
        ];
      };
    };
  };
}
