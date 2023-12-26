{ ... }:

{
  imports = [
    ./boot.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
