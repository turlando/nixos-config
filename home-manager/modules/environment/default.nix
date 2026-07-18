let
  age = ./age.nix;
  host-name = ./host-name.nix;
  syncthing = ./syncthing.nix;
in
{
  inherit age host-name syncthing;
  default.imports = [
    age
    host-name
    syncthing
  ];
}
