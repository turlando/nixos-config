{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption types;

  snapshotName = dataset: "${dataset.name}@${dataset.snapshot}";

  mkDatasetService = dataset:
    mkIf (config.services.ephemeral.enable && dataset.enable) {
      "ephemeral@${dataset.name}" = {
        description = ''
          Rollback ZFS dataset ${dataset.name} to ${snapshotName dataset}
        '';
        wantedBy = [ "initrd.target" ];
        before = [ "sysroot.mount" ];
        after = [ "zfs-import.target" ];
        path = [ pkgs.zfs ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = [
            # Check that the snapshot exists
            "@${pkgs.zfs}/bin/zfs zfs list -t snapshot ${snapshotName dataset}"
            # Roll back
            "@${pkgs.zfs}/bin/zfs zfs rollback -r ${snapshotName dataset}"
          ];
        };
      };
    };
in {
  options.services.ephemeral = {
    enable = mkEnableOption ''
      Ephemeral ZFS datasets.

      When enabled, selected ZFS datasets are automatically rolled
      back to a predefined snapshot at boot (inside the initrd).
      This allows the system to boot into a clean, reproducible
      state on every restart.
    '';

    datasets = mkOption {
      description = ''
        ZFS datasets to manage ephemerally. Each attribute key must
        be the dataset name, and its value is a submodule describing
        how that dataset should be handled.

        At boot, systemd services in the initrd will automatically
        roll back these datasets to the chosen snapshot. This makes
        it possible to run an "immutable" or stateless root system,
        with persistence managed separately (e.g. via
        `environment.persistence`).
      '';

      default = {};

      example = {
        "rpool/nixos/root" = {
          enable = true;
          snapshot = "blank";
        };
        "rpool/nixos/home" = {
          enable = true;
          snapshot = "empty";
        };
      };

      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          enable = mkEnableOption ''
            Ephemeral management for dataset “${name}”.

            If enabled, the dataset will be rolled back to the
            configured snapshot during initrd boot.
          '';

          name = mkOption {
            type = types.str;
            default = name;
            readOnly = true;
            internal = true;
            description = ''
              The ZFS dataset name. This is taken from the attribute
              key in `services.ephemeral.datasets` and is not meant
              to be set manually.
            '';
          };

          snapshot = mkOption {
            type = types.str;
            default = "empty";
            example = "blank";
            description = ''
              Name of the snapshot to roll back to at boot.

              For example, if `snapshot = "blank"` and the dataset is
              `rpool/nixos/root`, the rollback target will be
              `rpool/nixos/root@blank`.
            '';
          };
        };
      }));

    };
  };

  config = {
    assertions = [{
      assertion = config.services.ephemeral.enable
                  -> config.boot.initrd.systemd.enable;
      message = "services.ephemeral requires systemd in the initrd.";
    }];

    boot.initrd.systemd.services = mkMerge
      (map mkDatasetService (builtins.attrValues config.services.ephemeral.datasets));
  };
}
