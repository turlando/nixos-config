{ lib }:
{
  lib = import ./lib { inherit lib; };
  modules = import ./modules { inherit lib; };
}
