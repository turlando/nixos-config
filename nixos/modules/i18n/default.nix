let
  extra-locale = ./extra-locale.nix;
in
{
  inherit extra-locale;
  default.imports = [ extra-locale ];
}
