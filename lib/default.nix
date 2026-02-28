{ lib }:

{
  age = import ./age.nix { inherit lib; };
}
