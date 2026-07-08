{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.environment.syncthingDeviceIds = mkOption {
    type = types.attrsOf types.str;
    readOnly = true;
    default = import ../../../secrets/syncthing-device-ids.nix;
    description = ''
      Catalog of syncthing device IDs, keyed by host. Each ID is the
      fingerprint of that host's syncthing-<host>-cert.age certificate, and so
      is public data.

      The home-manager counterpart of the NixOS environment.syncthingDeviceIds
      accessor: both read the same secrets/syncthing-device-ids.nix. Home
      configurations reference an entry as
      `config.environment.syncthingDeviceIds.<host>` when declaring syncthing
      devices, so it is always clear which peer is meant.
    '';
  };
}
