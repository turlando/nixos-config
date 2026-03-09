{ self, agenix, disko, nixpkgs, nixpkgs-unstable, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";

  specialArgs = {
    lib-age = self.lib.age;
    pkgs-unstable = import nixpkgs-unstable {
      system = "x86_64-linux";
    };
  };

  modules = [
    agenix.nixosModules.default
    disko.nixosModules.default

    self.nixosModules.modules.environment.persistence
    self.nixosModules.modules.services.ephemeral

    self.nixosModules.profiles.base
    self.nixosModules.profiles.age
    self.nixosModules.profiles.zfs
    self.nixosModules.profiles.openssh-server

    ./hardware.nix
    ./disko.nix
    ./configuration.nix
    ./containers
  ];
}
