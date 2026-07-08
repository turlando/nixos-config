{ self, agenix, disko, nixpkgs, nixpkgs-unstable, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";

  specialArgs = {
    inherit self;
    pkgs-unstable = import nixpkgs-unstable {
      system = "x86_64-linux";
    };
    lib-age = self.lib.age;
  };

  modules = [
    agenix.nixosModules.default
    disko.nixosModules.default

    self.nixosModules.modules.environment.ids
    self.nixosModules.modules.environment.persistence
    self.nixosModules.modules.environment.ssh-public-keys
    self.nixosModules.modules.services.ephemeral
    self.nixosModules.modules.services.journald

    self.nixosModules.profiles.base
    self.nixosModules.profiles.boot-grub
    self.nixosModules.profiles.age
    self.nixosModules.profiles.zfs
    self.nixosModules.profiles.initrd-openssh-server
    self.nixosModules.profiles.openssh-server

    ./hardware.nix
    ./disko.nix
    ./storage.nix
    ./configuration.nix
    ./networking.nix
    ./containers
  ];
}
