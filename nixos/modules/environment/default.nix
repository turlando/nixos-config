let
  age = ./age.nix;
  persistence = ./persistence.nix;
  ssh = ./ssh.nix;
  syncthing = ./syncthing.nix;
  unix-ids = ./unix-ids.nix;
  wireguard = ./wireguard.nix;
in
{
  inherit age persistence ssh syncthing unix-ids wireguard;
  default.imports = [
    age
    persistence
    ssh
    syncthing
    unix-ids
    wireguard
  ];
}
