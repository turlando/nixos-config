{ lib }:
{
  age = import ./age.nix { inherit lib; };
  net = import ./net.nix { inherit lib; };
}
