# WireGuard devices, keyed by host. Each publicKey is the public half of that
# host's wireguard-<host>-key.age private secret, so these are public
# identifiers, not secrets. A listening device (the hub) also carries its
# dial-in endpoint (host:port). Surfaced by the environment.wireguardDevices
# accessor; host configs reference a peer as
# config.environment.wireguardDevices.<host>.{publicKey,endpoint} when
# declaring peers.
{
  creusa = {
    publicKey = "f3/XInYgN0aeeydzjsmRM5SaCUwjjb636MNJCxwRunE=";
    endpoint = "46.225.229.141:51820";
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
