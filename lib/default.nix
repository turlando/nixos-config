{ lib }:

{
  age = import ./age.nix { inherit lib; };
  mkHomeConfiguration = import ./mk-home-configuration.nix;
  mkNixosSystem = import ./mk-nixos-system.nix;
}
