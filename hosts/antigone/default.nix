{ ... }:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./networking.nix
    ./storage.nix
  ];

  system.stateVersion = "23.11";
}
