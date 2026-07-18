# WireGuard devices, keyed by host. Each publicKey is the public half of that
# host's wireguard-<host>-key.age private secret, so these are public
# identifiers, not secrets. A listening device (the hub) also carries its
# listen port and its dial-in endpoint, composed from its public address in
# network.nix so the two cannot drift apart. Surfaced by the
# environment.wireguard.devices accessor; host configs reference a peer as
# config.environment.wireguard.devices.<host>.{publicKey,endpoint,listenPort}
# when declaring peers.
let
  network = import ./network.nix;

  creusa-listen-port = 51820;
in
{
  creusa = {
    publicKey = "f3/XInYgN0aeeydzjsmRM5SaCUwjjb636MNJCxwRunE=";
    listenPort = creusa-listen-port;
    endpoint = "${network.hosts.creusa.interfaces.eth0.address}:${toString creusa-listen-port}";
  };
  antigone = {
    publicKey = "SkHq3/Od7nJZmZjffyxtVw+qyxyrB/GW+HNFS6N/qnY=";
  };
  # Unlock-only identity baked into antigone's initrd; see secrets.nix.
  antigone-initrd = {
    publicKey = "DbcrDXoGFHHCa0s8GclHUxVzOHHW0QpINuTJPin5RCU=";
  };
  medea = {
    publicKey = "O0hJgahCGphLASTUIW25yuTOVtPd96bDH7lSd8swAAo=";
  };
}
