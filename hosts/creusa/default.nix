{ self, lib, nixpkgs, flake-utils, ... }:

nixpkgs.lib.nixosSystem rec {
  system = flake-utils.lib.system.aarch64-linux;
  specialArgs = { inherit lib; };
  modules = [
    { system.stateVersion = "24.05"; }
    self.nixosModules.defaults
    self.nixosModules.ephemeral
    self.nixosModules.state
    self.nixosModules.zpools
    ./configuration.nix
    ./hardware.nix
  ];
}
