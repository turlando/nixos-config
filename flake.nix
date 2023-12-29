{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs, ... }@inputs: let 
    lib = nixpkgs.lib.extend (final: prev: import ./lib prev);
  in {
    packages = {
      "x86_64-linux" = import ./pkgs nixpkgs.legacyPackages."x86_64-linux";
    };

    nixosConfigurations = {
      antigone  = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit lib; inherit (self) packages; };
        modules = [ ./nixos ./hosts/antigone ];
      };
    };
  };
}
