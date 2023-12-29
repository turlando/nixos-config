{ ... }:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./storage.nix
    ./networking.nix
    ./users.nix
    ./packages.nix
    ./alerting.nix
    ./virtualisation.nix
    ./services
  ];

  system.stateVersion = "23.11";
}
