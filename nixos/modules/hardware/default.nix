let
  framework = ./framework.nix;
in
{
  inherit framework;
  default.imports = [ framework ];
}
