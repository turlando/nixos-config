{ self, lib, nixpkgs, nixpkgs-unstable, flake-utils, ... }:

nixpkgs.lib.nixosSystem rec {
  system = flake-utils.lib.system.x86_64-linux;
  specialArgs = {
    inherit self lib;
    pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
  };
  modules = [
    { system.stateVersion = "25.05"; }
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
