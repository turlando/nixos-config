{ ... }:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./storage.nix
    ./networking.nix
    ./desktop.nix
  ];

  system.stateVersion = "23.11";
}
