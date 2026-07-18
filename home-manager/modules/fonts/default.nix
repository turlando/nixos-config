let
  families = ./families.nix;
in
{
  inherit families;
  default.imports = [ families ];
}
