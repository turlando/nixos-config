{ self, lib, nixpkgs, flake-utils, ... }:

nixpkgs.lib.nixosSystem rec {
  system = flake-utils.lib.system.aarch64-linux;
  specialArgs = { inherit self lib; };
  modules = [
    { system.stateVersion = "24.05"; }
    (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
    self.nixosModules.defaults
    self.nixosModules.ephemeral
    self.nixosModules.state
    self.nixosModules.zpools
    ./configuration.nix
    ./hardware.nix
    ./services
  ];
}
