# WireGuard devices, keyed by host. Each publicKey is the public half of that
# host's wireguard-<host>-key.age private secret, so these are public
# identifiers, not secrets. Surfaced by the environment.wireguardDevices
# accessor; host configs reference a peer as
# config.environment.wireguardDevices.<host>.publicKey when declaring peers.
{
  creusa = {
    publicKey = "f3/XInYgN0aeeydzjsmRM5SaCUwjjb636MNJCxwRunE=";
  };
  antigone = {
    publicKey = "SkHq3/Od7nJZmZjffyxtVw+qyxyrB/GW+HNFS6N/qnY=";
  };
  medea = {
    publicKey = "O0hJgahCGphLASTUIW25yuTOVtPd96bDH7lSd8swAAo=";
  };
}
