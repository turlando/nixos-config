{ config, lib, ... }:

let
  inherit (builtins) length;
  inherit (lib) mkAfter mkIf mkOption types;
  inherit (lib.attrsets) mergeAttrsets;
  inherit (lib.filesystems) bootFileSystem;
  inherit (lib.grub) grubMirroredBoots;
  inherit (lib.lists) imap1;
in

{
  options = {
    boot = {
      ephemeral = {
        enable = mkOption {
          type = types.bool;
          default = false;
          example = true;
          description = ""; # TODO: add description
        };

        dataset = mkOption {
          type = types.str;
          example = "system/root@empty";
          description = ""; # TODO: add description
        };

        stateDir = mkOption {
          type = types.path;
          default = /var/state;
          description = ""; # TODO: add description
        };
      };

      drives = mkOption {
        type = types.nonEmptyListOf types.path;
        example = [ /dev/disk/by-id/foo /dev/disk/by-id/bar ];
        description = ""; # TODO: add description
      };

      partitions = mkOption {
        type = types.nonEmptyListOf types.path;
        example = [ /dev/disk/by-partlabel/foo /dev/disk/by-partlabel/bar ];
        description = ""; # TODO: add description
      };
    };
  };

  config = {
    boot.initrd.postDeviceCommands =
      mkIf
        config.boot.ephemeral.enable
        (mkAfter "zfs rollback -r ${config.boot.ephemeral.dataset}");

    boot.loader.grub.mirroredBoots =
      mkIf
        (length config.boot.drives > 1)
        (grubMirroredBoots config.boot.drives);

    fileSystems =
      mergeAttrsets (imap1 bootFileSystem config.boot.partitions);
  };
}
