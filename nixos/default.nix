{ ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./storage.nix
    ./services
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
