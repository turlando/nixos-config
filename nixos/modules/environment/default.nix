let
  age = ./age.nix;
  ids = ./ids.nix;
  persistence = ./persistence.nix;
  ssh-public-keys = ./ssh-public-keys.nix;
  syncthing-devices = ./syncthing-devices.nix;
  wireguard-devices = ./wireguard-devices.nix;
in
{
  inherit age ids persistence ssh-public-keys syncthing-devices wireguard-devices;
  default.imports = [
    age
    ids
    persistence
    ssh-public-keys
    syncthing-devices
    wireguard-devices
  ];
}
