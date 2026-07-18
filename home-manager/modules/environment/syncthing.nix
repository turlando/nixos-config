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

      The home-manager counterpart of the NixOS environment.syncthing.devices
      accessor: both read the same registry/syncthing-devices.nix. An entry maps
      directly onto services.syncthing.settings.devices.<name>.
    '';
  };
}
