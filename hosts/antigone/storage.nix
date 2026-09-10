{ config, lib, pkgs, ... }:
let
  musicDatasets = config.disko.devices.zpool.storage.datasets;
  libraryDirs = [
    musicDatasets."music/electronic-flac".mountpoint
    musicDatasets."music/electronic-mp3".mountpoint
  ];
in
{
  # storage-music owns the shared music datasets. Its gid is pinned so the
  # group is identical on the host and inside the slskd/syncthing containers
  # (which run privateUsers = false); members get to it from either side.
  users.groups.storage-music.gid = config.environment.unixIds.gids.storage-music;

  disko.devices.zpool.storage.datasets = {
    "music" = {
      type = "zfs_fs";
      options = {
        canmount = "off";
      };
    };

    # Master FLAC library (beets writes, slskd shares) and its MP3 export
    # (beets converts, syncthing replicates). acltype=posixacl is inherited
    # from the pool root; passthrough keeps chmod from discarding the group
    # ACLs applied by storage-music-perms below.
    #
    # nofail: the storage pool is the NAS side of the box. A failed import or
    # mount degrades only the units that RequiresMountsFor these paths (the
    # containers, the perms oneshot); it never fails local-fs.target and with
    # it the router's boot.
    "music/electronic-flac" = {
      type = "zfs_fs";
      mountpoint = "/srv/music/electronic-flac";
      mountOptions = [ "nofail" ];
      options = {
        recordsize = "1M";
        atime = "off";
        aclmode = "passthrough";
      };
    };

    "music/electronic-mp3" = {
      type = "zfs_fs";
      mountpoint = "/srv/music/electronic-mp3";
      mountOptions = [ "nofail" ];
      options = {
        recordsize = "1M";
        atime = "off";
        aclmode = "passthrough";
      };
    };
  };

  # The storage datasets import and mount in stage 2, so ownership and the
  # inherited group ACL are applied from a oneshot ordered after their mount
  # units rather than tmpfiles (which would race the late mount) or a
  # postCreateHook (which sees the /mnt altroot). Idempotent: setgid + a
  # default ACL make new files group-rwX and group-owned, so
  # slskd/syncthing/tancredi share them via storage-music.
  systemd.services.storage-music-perms = {
    description = "Ownership and default ACLs for the storage-music datasets";
    unitConfig.RequiresMountsFor = libraryDirs;
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.acl pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for d in ${lib.concatStringsSep " " libraryDirs}; do
        chown root:storage-music "$d"
        chmod 2770 "$d"
        setfacl -d -m u::rwX,g::rwX,g:storage-music:rwX,o::--- "$d"
      done
    '';
  };
}
