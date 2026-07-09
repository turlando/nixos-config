{
  ids = import ./ids.nix;
  persistence = import ./persistence.nix;
  ssh-public-keys = import ./ssh-public-keys.nix;
  syncthing-devices = import ./syncthing-devices.nix;
  wireguard-devices = import ./wireguard-devices.nix;
}
