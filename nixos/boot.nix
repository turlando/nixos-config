{ config, lib, ... }:

let
  inherit (builtins) length;
  inherit (lib) mkAfter mkIf mkMerge mkOption types;
  inherit (lib.attrsets) mergeAttrsets;
  inherit (lib.filesystems) bootFileSystem efiFileSystem;
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
        (config.boot.loader.grub.enable && !config.boot.loader.grub.efiSupport
         && length config.boot.drives > 1)
        (grubMirroredBoots config.boot.drives);

    fileSystems = mkMerge [
      (mkIf
        (!config.boot.loader.grub.efiSupport && length config.boot.partitions > 1)
        (mergeAttrsets (imap1 bootFileSystem config.boot.partitions)))
      (mkIf
        (config.boot.loader.grub.efiSupport && length config.boot.partitions == 1)
        (efiFileSystem (builtins.elemAt config.boot.partitions 0)))
    ];
  };
}
