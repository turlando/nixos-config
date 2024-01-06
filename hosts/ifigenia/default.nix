{ ... }:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./storage.nix
    ./networking.nix
  ];

  system.stateVersion = "23.11";
}
