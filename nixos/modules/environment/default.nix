let
  ids = ./ids.nix;
  persistence = ./persistence.nix;
  ssh-public-keys = ./ssh-public-keys.nix;
  syncthing-devices = ./syncthing-devices.nix;
  wireguard-devices = ./wireguard-devices.nix;
in
{
  inherit ids persistence ssh-public-keys syncthing-devices wireguard-devices;
  default.imports = [
    ids
    persistence
    ssh-public-keys
    syncthing-devices
    wireguard-devices
  ];
}
