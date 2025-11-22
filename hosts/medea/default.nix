{ self, disko, nixos-hardware, nixpkgs, agenix, nixvirt, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";

  modules = [
    {
      _module.args = {
        inherit nixvirt;
      };
    }

    agenix.nixosModules.default
    disko.nixosModules.disko
    nixos-hardware.nixosModules.framework-amd-ai-300-series
    nixvirt.nixosModules.default

    self.nixosModules.boot.silent
    self.nixosModules.environment.persistence
    self.nixosModules.i18n.extra-locale

    self.nixosModules.secrets

    self.nixosModules.profiles.base
    self.nixosModules.profiles.graphical
    self.nixosModules.profiles.libvirt

    self.nixosModules.users.root
    self.nixosModules.users.tancredi
    self.nixosModules.users.luminovo

    ./configuration.nix
    ./disko.nix
    ./hardware.nix
    ./libvirt
  ];
}
