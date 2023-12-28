{ ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./storage.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
