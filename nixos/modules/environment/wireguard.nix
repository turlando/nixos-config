{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.environment.wireguard.devices = mkOption {
    type = types.attrsOf (types.submodule {
      options.publicKey = mkOption {
        type = types.str;
        description = "WireGuard device public key.";
      };
      options.endpoint = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Dial-in endpoint (host:port) for a listening device such as the hub;
          null for spokes and roaming clients.
        '';
      };
      options.listenPort = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = ''
          UDP listen port for a listening device such as the hub; null for
          spokes and roaming clients.
        '';
      };
    });
    readOnly = true;
    default = import ../../../registry/wireguard-devices.nix;
    description = ''
      Catalog of WireGuard devices, keyed by host name, each carrying its
      public key as public data.

      This module is only the accessor: the devices live in
      registry/wireguard-devices.nix. A configuration references a peer as
      `config.environment.wireguard.devices.<name>.publicKey` when declaring
      WireGuard peers, so it is always clear whose key is used.
    '';
  };
}
