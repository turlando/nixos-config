{ lib }:
{
  network = import ./network.nix { inherit lib; };
}
