{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;
  inherit (lib.attrsets) attrValues;

  mkService = dataset:
  let
    snapshot = "${dataset.name}@${dataset.snapshot}";
  in
    mkIf config.services.ephemeral.enable {
      "ephemeral@${dataset.name}" = {
        description = "Rollback ZFS dataset ${dataset.name} to ${snapshot}";
        wantedBy = [ "initrd.target" ];
        before = [ "sysroot.mount" ];
        after = [ "zfs-import.target" ];
        path = with pkgs; [ zfs ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = "zfs rollback -r ${snapshot}";
      };
    };
in

{
  options.services.ephemeral = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
    };

    datasets = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }@attrs:
          {
            options = {
              name = mkOption {
                type = types.str;
                default = name;
                readOnly = true;
                visible = false;
              };

              enable = mkOption {
                type = types.bool;
                default = false;
                example = true;
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
      mkMerge (map mkService (attrValues config.services.ephemeral.datasets));
  };
}
