{ self, agenix, disko, nixos-hardware, nixpkgs, nixvirt, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";

  specialArgs = {
    nixvirt-lib = nixvirt.lib;
  };

  modules = [
    agenix.nixosModules.default
    disko.nixosModules.default
    nixos-hardware.nixosModules.framework-amd-ai-300-series
    nixvirt.nixosModules.default

    self.nixosModules.modules.boot.silent
    self.nixosModules.modules.environment.persistence
    self.nixosModules.modules.i18n.extra-locale

    self.nixosModules.secrets

    self.nixosModules.profiles.base
    self.nixosModules.profiles.graphical
    self.nixosModules.profiles.zfs
    self.nixosModules.profiles.clamav
    self.nixosModules.profiles.libvirt

    ./hardware.nix
    ./configuration.nix
    ./disko.nix
    ./users.nix
    ./libvirt
  ];
}
