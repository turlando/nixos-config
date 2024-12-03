{ self, lib, nixpkgs, nixpkgs-unstable, flake-utils, ... }:

nixpkgs.lib.nixosSystem rec {
  system = flake-utils.lib.system.x86_64-linux;
  specialArgs = {
    inherit self lib;
    pkgs-unstable = import nixpkgs-unstable { inherit system; };
  };
  modules = [
    { system.stateVersion = "24.11"; }
    self.nixosModules.defaults
    self.nixosModules.ephemeral
    self.nixosModules.state
    self.nixosModules.zpools
    ./hardware.nix
    ./configuration.nix
    ./booting.nix
    ./networking.nix
    ./storage.nix
    ./alerting.nix
    ./services
  ];
}
