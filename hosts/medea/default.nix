{ self, agenix, disko, nixos-hardware, nixpkgs, nixvirt, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";

  modules = [
    nixos-hardware.nixosModules.framework-amd-ai-300-series

    self.nixosModules.boot.silent
    self.nixosModules.environment.persistence
    self.nixosModules.i18n.extra-locale

    (self.nixosModules.secrets { inherit agenix; })

    self.nixosModules.profiles.base
    self.nixosModules.profiles.graphical
    (self.nixosModules.profiles.libvirt { inherit nixvirt; })

    self.nixosModules.users.root
    self.nixosModules.users.tancredi
    self.nixosModules.users.luminovo

    ./configuration.nix
    ./hardware.nix
    (import ./disko.nix { inherit disko; })
    (import ./libvirt { inherit nixvirt; })
  ];
}
