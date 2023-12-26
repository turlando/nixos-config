{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let 
      lib = nixpkgs.lib.extend (final: prev: import ./lib prev);
    in {
      nixosConfigurations = {
        antigone  = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; inherit lib; };
          modules = [ ./nixos ./hosts/antigone ];
        };
      };
    };
}
