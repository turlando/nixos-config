{ ... }:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./networking.nix
  ];

  system.stateVersion = "23.11";
}
