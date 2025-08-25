{ self, disko, nixos-hardware, nixpkgs, agenix, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";

  modules = [
    agenix.nixosModules.default
    disko.nixosModules.disko
    nixos-hardware.nixosModules.framework-amd-ai-300-series

    self.nixosModules.boot.silent
    self.nixosModules.environment.persistence
    self.nixosModules.i18n.extra-locale
    self.nixosModules.security.run0
    self.nixosModules.services.ephemeral

    self.nixosModules.secrets

    self.nixosModules.profiles.base
    self.nixosModules.profiles.graphical

    self.nixosModules.users.root
    self.nixosModules.users.tancredi

    ./configuration.nix
    ./disko.nix
    ./hardware.nix
  ];
}
