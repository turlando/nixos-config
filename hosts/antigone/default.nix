flake:

flake.lib.mkNixosSystem {
  inherit flake;
  system = "x86_64-linux";

  modules = [
    flake.inputs.agenix.nixosModules.default
    flake.inputs.disko.nixosModules.default

    flake.nixosModules.modules.default

    flake.nixosModules.profiles.base
    flake.nixosModules.profiles.boot-grub
    flake.nixosModules.profiles.age
    flake.nixosModules.profiles.zfs
    flake.nixosModules.profiles.initrd-openssh-server
    flake.nixosModules.profiles.openssh-server

    ./hardware.nix
    ./disko.nix
    ./storage.nix
    ./configuration.nix
    ./networking.nix
    ./containers
  ];
}
