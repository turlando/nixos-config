{ config, ... }:
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

      # Four 4 TB HGST disks forming the storage pool (RAID10, two mirrors).
      storage-1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-HGST_HUS724040ALA640_PN1334PBJMA8AS";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            label = "storage-1";
            content = { type = "zfs"; pool = "storage"; };
          };
        };
      };
      storage-2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-HGST_HUS724040ALA640_PN1334PBJN6DGS";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            label = "storage-2";
            content = { type = "zfs"; pool = "storage"; };
          };
        };
      };
      storage-3 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-HGST_HUS724040ALA640_PN1334PBJX3R3S";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            label = "storage-3";
            content = { type = "zfs"; pool = "storage"; };
          };
        };
      };
      storage-4 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-HGST_HUS724040ALA640_PN2334PBJTM5GT";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            label = "storage-4";
            content = { type = "zfs"; pool = "storage"; };
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
        compression = "zstd";
        normalization = "formD";
        xattr = "sa";

        # Hold ~20% of the pool free: a refreservation on the dataless root
        # keeps that space unavailable to the child datasets, so ZFS never
        # fills enough to fragment and slow down. A plain reservation would
        # not do this; it covers descendants, which could still consume it.
        refreservation = "95G";

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
            atime = "off";
          };
        };

        "nixos/journal" = {
          type = "zfs_fs";
          mountpoint = "/var/log/journal";
          options = {
            recordsize = "16K";
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

        # Parent for the nspawn container datasets defined under
        # hosts/antigone/containers/; each child holds a container's journal
        # and data.
        "containers" = {
          type = "zfs_fs";
          options = {
            canmount = "off";
          };
        };
      };
    };

    zpool.storage = {
      type = "zpool";

      # RAID10: two mirror vdevs, striped. Survives one disk per mirror (two
      # total if they land in different mirrors), with fast resilvers.
      #
      # disko requires each topology member to be one of the partitions that
      # reference this pool, named by its by-partlabel path.
      mode = {
        topology = {
          type = "topology";
          vdev = [
            {
              mode = "mirror";
              members = [
                "/dev/disk/by-partlabel/storage-1"
                "/dev/disk/by-partlabel/storage-2"
              ];
            }
            {
              mode = "mirror";
              members = [
                "/dev/disk/by-partlabel/storage-3"
                "/dev/disk/by-partlabel/storage-4"
              ];
            }
          ];
        };
      };

      options.ashift = "12";

      rootFsOptions = {
        # Passphrase encryption. The passphrase lives in agenix and is read
        # from that file for unattended unlock once the root pool is open;
        # the same passphrase is typeable at a prompt for recovery on any
        # machine (`zfs load-key -L prompt storage`).
        encryption = "aes-256-gcm";
        keyformat = "passphrase";
        keylocation = "file://${config.age.secrets.zfs-passphrase-storage.path}";

        dnodesize = "auto";
        redundant_metadata = "most";
        compression = "zstd";
        normalization = "formD";
        xattr = "sa";
        acltype = "posixacl";

        # Hold ~20% of the pool free: a refreservation on the dataless root
        # keeps that space unavailable to the child datasets, so ZFS never
        # fills enough to fragment and slow down. A plain reservation would
        # not do this; it covers descendants, which could still consume it.
        refreservation = "1.5T";

        relatime = "on";
        canmount = "off";
        mountpoint = "none";
      };
    };
  };
}
