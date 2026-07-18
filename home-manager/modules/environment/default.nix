let
  syncthing-devices = ./syncthing-devices.nix;
in
{
  inherit syncthing-devices;
  default.imports = [ syncthing-devices ];
}
