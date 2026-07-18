let
  silent = ./silent.nix;
in
{
  inherit silent;
  default.imports = [ silent ];
}
