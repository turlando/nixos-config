let
  host-name = ./host-name.nix;
  syncthing-devices = ./syncthing-devices.nix;
in
{
  inherit host-name syncthing-devices;
  default.imports = [
    host-name
    syncthing-devices
  ];
}
