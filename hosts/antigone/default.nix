{ self, lib, nixpkgs, flake-utils, ... }:

nixpkgs.lib.nixosSystem {
  system = flake-utils.lib.system.x86_64-linux;
  specialArgs = { inherit self lib; };
  modules = [
    { system.stateVersion = "23.11"; }
    self.nixosModules.defaults
    self.nixosModules.ephemeral
    self.nixosModules.state
    self.nixosModules.zpools
    ./hardware.nix
    ./configuration.nix
    ./booting.nix
    ./networking.nix
    ./storage.nix
    ./virtualisation.nix
    ./alerting.nix
    ./services
  ];
}
