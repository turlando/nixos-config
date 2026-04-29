{ lib }:
{
  persistence = import ./persistence.nix { inherit lib; };
}
