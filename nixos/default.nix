{ ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
