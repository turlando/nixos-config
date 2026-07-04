{
  disko.devices = {
    disk = {
      medea = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7DNNU0Y622001W";

        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "4G";
              label = "medea-efi";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            medea = {
              size = "100%";
              label = "medea-system";
              content = {
                type = "zfs";
                pool = "medea";
              };
            };
          };
        };
      };
    };

    zpool = {
      medea = {
        type = "zpool";
        options = {
          ashift = "12";
        };

        rootFsOptions = {
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "prompt";
          dnodesize = "auto";
          redundant_metadata = "most";
          checksum = "fletcher4";
          compression = "zstd";
          normalization = "formD";
          xattr = "sa";

          # Hold ~20% of the pool free: a refreservation on the dataless root
          # keeps that space unavailable to the child datasets, so ZFS never
          # fills enough to fragment and slow down. A plain reservation would
          # not do this; it covers descendants, which could still consume it.
          refreservation = "400G";

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
              zfs list -t snapshot medea/nixos/ROOT@empty >/dev/null 2>&1 || \
                zfs snapshot medea/nixos/ROOT@empty
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

          "home" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
            };
          };

          "home/tancredi" = {
            type = "zfs_fs";
            mountpoint = "/home/tancredi";
            options = {
              acltype = "posixacl";
            };
          };

          "home/luminovo" = {
            type = "zfs_fs";
            mountpoint = "/home/luminovo";
            options = {
              acltype = "posixacl";
            };
          };

          "libvirt" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
            };
          };

          "libvirt/tersicore" = {
            type = "zfs_volume";
            size = "128G";
            options = {
              volblocksize = "16K";
              primarycache = "metadata";
              sync = "disabled";
            };
          };
        };
      };
    };
  };
}
