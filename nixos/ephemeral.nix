{ config, lib, pkgs, ... }:

let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) types;
in

{
  options.services.ephemeral = {
    enable = mkEnableOption "ephemeral";

    datasets = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }@attrs:
          {
            options = {
              enable = mkEnableOption "ephemeral for dataset ${name}";

              name = mkOption {
                type = types.str;
                default = name;
                readOnly = true;
                visible = false;
              };

              snapshot = mkOption {
                type = types.str;
                default = "empty";
              };
            };
          }
        )
      );
    };
  };

  config = {
    assertions = [
      {
        assertion = config.services.ephemeral.enable
                    -> config.boot.initrd.systemd.enable;
        message = "ephemeral requires systemd in the initrd";
      }
    ];

    boot.initrd.systemd.services =
      let
        # Return the name of the snapshot dataset given an entry of
        # services.ephemeral.datasets.
        snapshot = dataset: "${dataset.name}@${dataset.snapshot}";

        mkService = dataset:
          mkIf config.services.ephemeral.enable {
            "ephemeral@${dataset.name}" = {
              description = "Rollback ZFS dataset ${dataset.name} to ${snapshot dataset}";
              wantedBy = [ "initrd.target" ];
              before = [ "sysroot.mount" ];
              after = [ "zfs-import.target" ];
              path = with pkgs; [ zfs ];
              unitConfig.DefaultDependencies = "no";
              serviceConfig.Type = "oneshot";
              script = "zfs rollback -r ${snapshot dataset}";
            };
          };
      in
        mkMerge (map mkService (attrValues config.services.ephemeral.datasets));
  };
}
