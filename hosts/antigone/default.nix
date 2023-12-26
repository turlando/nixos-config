{ ... }:

{
  imports = [
    ./hardware.nix
    ./boot.nix
  ];

  system.stateVersion = "23.11";
}
