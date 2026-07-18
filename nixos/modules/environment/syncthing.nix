{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.environment.syncthing.devices = mkOption {
    type = types.attrsOf (types.submodule {
      options.id = mkOption {
        type = types.str;
        description = "Syncthing device ID (the certificate fingerprint).";
      };
    });
    readOnly = true;
    default = import ../../../registry/syncthing-devices.nix;
    description = ''
      Catalog of syncthing devices, keyed by name, each carrying its device id
      (a certificate fingerprint) as public data.

      This module is only the accessor: the devices live in
      registry/syncthing-devices.nix. An entry maps directly onto
      services.syncthing.settings.devices.<name>, so a configuration can set
      `settings.devices.<name> = config.environment.syncthing.devices.<name>`.
    '';
  };
}
