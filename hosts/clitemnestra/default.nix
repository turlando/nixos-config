{ self, lib, nixpkgs, flake-utils, ... }:

nixpkgs.lib.nixosSystem rec {
  system = flake-utils.lib.system.x86_64-linux;
  specialArgs = { inherit self lib; };
  modules = [
    { system.stateVersion = "24.11"; }
    self.nixosModules.defaults
    self.nixosModules.ephemeral
    self.nixosModules.state
    self.nixosModules.zpools
    ./configuration.nix
    ./hardware.nix
    ./services
  ];
}
