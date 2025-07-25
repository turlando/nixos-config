{ self, lib, nixpkgs, nixos-hardware, flake-utils, ... }:

nixpkgs.lib.nixosSystem {
  system = flake-utils.lib.system.x86_64-linux;
  specialArgs = { inherit lib; };
  modules = [
    { system.stateVersion = "25.05"; }
    nixos-hardware.nixosModules.lenovo-thinkpad-x250
    self.nixosModules.defaults
    self.nixosModules.ephemeral
    self.nixosModules.state
    self.nixosModules.zpools
    ./hardware.nix
    ./configuration.nix
  ];
}
