flake:

flake.lib.mkNixosSystem {
  inherit flake;
  system = "x86_64-linux";

  modules = [
    flake.inputs.agenix.nixosModules.default
    flake.inputs.disko.nixosModules.default
    flake.inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    flake.inputs.nixvirt.nixosModules.default

    flake.nixosModules.modules.default

    flake.nixosModules.profiles.base
    flake.nixosModules.profiles.boot-systemd
    flake.nixosModules.profiles.age
    flake.nixosModules.profiles.zfs
    flake.nixosModules.profiles.libvirt
    flake.nixosModules.profiles.clamav
    flake.nixosModules.profiles.graphical
    flake.nixosModules.profiles.smartcard

    ./hardware.nix
    ./configuration.nix
    ./disko.nix
    ./users.nix
    ./libvirt
  ];
}
