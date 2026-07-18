let
  age = ./age.nix;
  host-name = ./host-name.nix;
  syncthing-devices = ./syncthing-devices.nix;
in
{
  inherit age host-name syncthing-devices;
  default.imports = [
    age
    host-name
    syncthing-devices
  ];
}
