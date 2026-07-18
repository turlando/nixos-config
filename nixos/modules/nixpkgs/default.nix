let
  unstable = ./unstable.nix;
in
{
  inherit unstable;
  default.imports = [ unstable ];
}
