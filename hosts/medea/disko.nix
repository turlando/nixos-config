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
          reservation = "400G";
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
            postCreateHook = "zfs snapshot medea/nixos/ROOT@empty";
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
        };
      };
    };
  };
}
