let
  age = ./age.nix;
  host-name = ./host-name.nix;
  network = ./network.nix;
  syncthing = ./syncthing.nix;
in
{
  inherit age host-name network syncthing;
  default.imports = [
    age
    host-name
    network
    syncthing
  ];
}
