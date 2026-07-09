{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.environment.wireguardDevices = mkOption {
    type = types.attrsOf (types.submodule {
      options.publicKey = mkOption {
        type = types.str;
        description = "WireGuard device public key.";
      };
    });
    readOnly = true;
    default = import ../../../registry/wireguard-devices.nix;
    description = ''
      Catalog of WireGuard devices, keyed by host name, each carrying its
      public key as public data.

      This module is only the accessor: the devices live in
      registry/wireguard-devices.nix. A configuration references a peer as
      `config.environment.wireguardDevices.<name>.publicKey` when declaring
      WireGuard peers, so it is always clear whose key is used.
    '';
  };
}
