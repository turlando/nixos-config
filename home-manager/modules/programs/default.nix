let
  firefox = ./firefox.nix;
  thunderbird = ./thunderbird.nix;
in
{
  inherit firefox thunderbird;
  default.imports = [
    firefox
    thunderbird
  ];
}
