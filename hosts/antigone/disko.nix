{
  disko.devices = {
    disk = {
      # Two identical SATA SSDs, partitioned symmetrically (ESP + ZFS
      # member). GRUB is installed to BOTH ESPs (mounted /boot/1 and
      # /boot/2) via boot.loader.grub.mirroredBoots, and both ESPs are
      # mounted nofail so the machine boots from whichever disk survives.
      # The ZFS partitions form the encrypted mirror pool.
      antigone-1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Lexar_SSD_NS100_512GB_MJ95272016149";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "2G";
              label = "antigone-efi-1";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/1";
                mountOptions = [ "umask=0077" "nofail" ];
              };
            };
            zfs = {
              size = "100%";
              label = "antigone-system-1";
              content = {
                type = "zfs";
                pool = "antigone";
              };
            };
          };
        };
      };

      antigone-2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Lexar_SSD_NS100_512GB_MJ95272016260";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "2G";
              label = "antigone-efi-2";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/2";
                mountOptions = [ "umask=0077" "nofail" ];
              };
            };
            zfs = {
              size = "100%";
              label = "antigone-system-2";
              content = {
                type = "zfs";
                pool = "antigone";
              };
            };
          };
        };
      };
    };

    zpool.antigone = {
      type = "zpool";
      mode = "mirror";

      options = {
        ashift = "12";
      };

      rootFsOptions = {
        # Native encryption at the pool root; every child dataset inherits
        # it. A single passphrase entered at boot unlocks the whole pool.
        encryption = "aes-256-gcm";
        keyformat = "passphrase";
        keylocation = "prompt";

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
          zfs list -t snapshot antigone/nixos/ROOT@empty >/dev/null 2>&1 || \
            zfs snapshot antigone/nixos/ROOT@empty
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
