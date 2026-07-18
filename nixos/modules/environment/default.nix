let
  age = ./age.nix;
  network = ./network.nix;
  persistence = ./persistence.nix;
  ssh = ./ssh.nix;
  syncthing = ./syncthing.nix;
  unix-ids = ./unix-ids.nix;
  wireguard = ./wireguard.nix;
in
{
  inherit age network persistence ssh syncthing unix-ids wireguard;
  default.imports = [
    age
    network
    persistence
    ssh
    syncthing
    unix-ids
    wireguard
  ];
}
