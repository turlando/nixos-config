{ self, agenix, disko, nixos-hardware, nixpkgs, nixvirt, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";

  specialArgs = {
    lib-age = self.lib.age;
    nixvirt-lib = nixvirt.lib;
  };

  modules = [
    agenix.nixosModules.default
    disko.nixosModules.default
    nixos-hardware.nixosModules.framework-amd-ai-300-series
    nixvirt.nixosModules.default

    self.nixosModules.modules.boot.silent
    self.nixosModules.modules.environment.persistence
    self.nixosModules.modules.hardware.framework
    self.nixosModules.modules.i18n.extra-locale

    self.nixosModules.profiles.base
    self.nixosModules.profiles.age
    self.nixosModules.profiles.zfs
    self.nixosModules.profiles.libvirt
    self.nixosModules.profiles.clamav
    self.nixosModules.profiles.graphical

    ./hardware.nix
    ./configuration.nix
    ./disko.nix
    ./users.nix
    ./libvirt
  ];
}
