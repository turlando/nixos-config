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

    self.nixosModules.modules.default

    self.nixosModules.profiles.base
    self.nixosModules.profiles.boot-systemd
    self.nixosModules.profiles.age
    self.nixosModules.profiles.zfs
    self.nixosModules.profiles.openssh-server

    ./hardware.nix
    ./disko.nix
    ./configuration.nix
    ./networking.nix
    ./containers
  ];
}
