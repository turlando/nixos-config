{
  disko.devices = {
    disk.creusa = {
      type = "disk";
      device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_113264805";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "512M";
            label = "creusa-efi";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          creusa = {
            size = "100%";
            label = "creusa-system";
            content = {
              type = "zfs";
              pool = "creusa";
            };
          };
        };
      };
    };

    zpool.creusa = {
      type = "zpool";
      options = {
        ashift = "12";
      };

      rootFsOptions = {
        dnodesize = "auto";
        redundant_metadata = "most";
        checksum = "fletcher4";
        compression = "zstd";
        normalization = "formD";
        xattr = "sa";
        reservation = "10G";
        relatime = "on";
        canmount = "off";
        mountpoint = "none";
      };

      datasets = {
        "nixos" = {
          type = "zfs_fs";
          options = {
            canmount = "off";
          };
        };

        "nixos/ROOT" = {
          type = "zfs_fs";
          mountpoint = "/";
          postCreateHook = ''
          zfs list -t snapshot creusa/nixos/ROOT@empty >/dev/null 2>&1 || \
            zfs snapshot creusa/nixos/ROOT@empty
          '';
          options = {
            acltype = "posixacl";
          };
        };

        "nixos/nix" = {
          type = "zfs_fs";
          options = {
            canmount = "off";
          };
        };

        "nixos/nix/store" = {
          type = "zfs_fs";
          mountpoint = "/nix/store";
          options = {
            recordsize = "1M";
            atime = "off";
            relatime = "off";
          };
        };

        "nixos/nix/var" = {
          type = "zfs_fs";
          mountpoint = "/nix/var";
          options = {
            recordsize = "16K";
            logbias = "latency";
            atime = "off";
          };
        };

        "nixos/journal" = {
          type = "zfs_fs";
          mountpoint = "/var/log/journal";
          options = {
            recordsize = "16K";
            logbias = "latency";
            primarycache = "metadata";
            sync = "disabled";
            atime = "off";
          };
        };

        "nixos/state" = {
          type = "zfs_fs";
          mountpoint = "/var/state";
          options = {
            acltype = "posixacl";
          };
        };
      };
    };
  };
}
