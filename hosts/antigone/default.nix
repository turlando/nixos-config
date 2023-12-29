{ ... }:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./networking.nix
    ./storage.nix
    ./alerting.nix
  ];

  system.stateVersion = "23.11";
}
