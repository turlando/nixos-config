{ config, lib, ... }:

let
  inherit (lib)
    concatStringsSep filterAttrs hasInfix mapAttrsToList mkIf mkOption types;

  cfg = config.services.journald.settings;
  activeSettings = filterAttrs (_: v: v != null) cfg;
in {
  options.services.journald.settings = mkOption {
    description = ''
      journald.conf(5) settings.

      Each attribute maps directly to a journald.conf directive and is written to
      a systemd drop-in file. Only non-null values are emitted. Do not duplicate
      these settings in services.journald.extraConfig.
    '';

    default = {};

    type = types.submodule {
      options = {
        SystemMaxUse = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "500M";
          description = ''
            Maximum disk space the journal may use (SystemMaxUse=). Accepts K, M,
            G, T suffixes. Journald vacuums old entries when exceeded.
          '';
        };

        SystemMaxFileSize = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "50M";
          description = ''
            Maximum size of individual journal files (SystemMaxFileSize=).
            Journald rotates to a new file when exceeded.
          '';
        };

        MaxRetentionSec = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "1month";
          description = ''
            Maximum time to store journal entries (MaxRetentionSec=). Accepts
            systemd time span syntax (e.g. "1month", "2week", "30d").
          '';
        };
      };
    };
  };

  config = {
    assertions =
      let
        extraCfg = config.services.journald.extraConfig;
      in
        map
          (key: {
            assertion = !(hasInfix "${key}=" extraCfg);
            message = ''
              services.journald.settings.${key} conflicts with a {key}= directive
              in services.journald.extraConfig.
            '';
          })
          (builtins.attrNames activeSettings);

    environment.etc."systemd/journald.conf.d/99-settings.conf" =
      mkIf (activeSettings != {}) {
        text = ''
          [Journal]
          ${concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${v}") activeSettings)}
        '';
      };
  };
}
