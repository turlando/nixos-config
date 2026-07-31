{ flake, config, ... }:
let
  # Bind the host-decrypted agenix secret through to the same path inside the
  # container.
  credentialsPath = config.age.secrets.slskd-credentials.path;

  # slskd's app-dir download tree: a container-side convention (not a disko
  # mountpoint).
  downloadsDir = "/var/lib/slskd/downloads";
  completeDownloadsDir = "${downloadsDir}/complete";
  incompleteDownloadsDir = "${downloadsDir}/incomplete";

  # Pinned ids from the registry, so slskd's uid and the storage-music gid
  # line up across the container boundary (privateUsers = false).
  slskdUid = config.environment.unixIds.uids.slskd;
  slskdGid = config.environment.unixIds.gids.slskd;
  storageMusicGid = config.environment.unixIds.gids.storage-music;

  # Master FLAC library on the storage pool, shared read-only through slskd.
  flacLibrary = config.disko.devices.zpool.storage.datasets."music/electronic-flac".mountpoint;

  # Private network namespace addressing: the container's veth peers with
  # antigone's shared services-side address.
  slskdAddress = config.environment.network.hosts.antigone-slskd.interfaces.svc0.address;
  servicesGateway = config.environment.network.hosts.antigone.interfaces.svc0.address;

  soulseekPort = config.containers.slskd.config.services.slskd.settings.soulseek.listen_port;

  unstable = config.nixpkgs.unstable.pkgs;
in
{
  disko.devices.zpool.antigone.datasets = {
    "containers/slskd" = {
      type = "zfs_fs";
      options = {
        canmount = "off";
      };
    };

    "containers/slskd/journal" = {
      type = "zfs_fs";
      mountpoint = "/var/containers/slskd/journal";
      options = {
        recordsize = "16K";
        primarycache = "metadata";
        sync = "disabled";
        atime = "off";
        # journald grants per-user journal access via POSIX ACLs
        acltype = "posixacl";
      };
    };

    "containers/slskd/data" = {
      type = "zfs_fs";
      mountpoint = "/var/containers/slskd/data";
      options = {
        # slskd's app dir: the SQLite database and config (downloads live on
        # storage). atime is useless here, and sync-disabled is safe on ZFS (a
        # crash loses at most the last txgs of reconstructable state, never
        # integrity).
        recordsize = "64K";
        atime = "off";
        sync = "disabled";
      };
    };
  };

  disko.devices.zpool.storage.datasets = {
    "downloads" = {
      type = "zfs_fs";
      options = {
        canmount = "off";
      };
    };

    "downloads/slskd" = {
      type = "zfs_fs";
      mountpoint = "/srv/downloads/slskd";
      options = {
        # slskd's downloads, in-progress and completed: large, sequential
        # media. A big recordsize maximizes throughput and compression
        # efficiency and cuts metadata overhead; atime is useless here.
        recordsize = "1M";
        atime = "off";
      };
    };
  };

  # The Soulseek listen port is the one P2P data port we expose on the
  # internet edge: DNAT it from wan0 into the container (the forward chain
  # accepts DNAT'd flows) and let slskd dial out to the server and peers
  # through the masqueraded services range. The web UI binds the veth and
  # is reached only through nginx's forward rule.
  networking.nat.forwardPorts = [
    {
      sourcePort = soulseekPort;
      proto = "tcp";
      destination = "${slskdAddress}:${toString soulseekPort}";
    }
  ];
  networking.nat.internalIPs = [ "${slskdAddress}/32" ];

  # The downloads dataset is on the storage pool, which imports and unlocks in
  # stage 2. ZFS non-legacy mounts aren't fstab-backed, so the container's
  # auto-generated RequiresMountsFor can't order against them; wait for
  # zfs-mount explicitly.
  systemd.services."container@slskd" = {
    after = [ "zfs-mount.service" ];
    requires = [ "zfs-mount.service" ];
  };

  containers.slskd = {
    ephemeral = true;
    autoStart = true;

    # Own network namespace: the container sees only its veth. nspawn's
    # resolv.conf handling is off, as it would bind the host's (which points
    # at loopback, container-local here); the container writes its own.
    privateNetwork = true;
    hostAddress = servicesGateway;
    localAddress = slskdAddress;
    extraFlags = [ "--resolv-conf=off" ];

    bindMounts = {
      "/var/log/journal" = {
        hostPath = config.disko.devices.zpool.antigone.datasets
          ."containers/slskd/journal".mountpoint;
        isReadOnly = false;
      };

      "/var/lib/slskd" = {
        hostPath = config.disko.devices.zpool.antigone.datasets
          ."containers/slskd/data".mountpoint;
        isReadOnly = false;
      };

      # Downloads (in-progress and completed) on the storage pool, mounted as a
      # submount of the app dir.
      "${downloadsDir}" = {
        hostPath = config.disko.devices.zpool.storage.datasets
          ."downloads/slskd".mountpoint;
        isReadOnly = false;
      };

      # FLAC library, read-only: slskd serves it on Soulseek but can never
      # modify it (the group would allow writes, so the ro mount is the guard).
      "${flacLibrary}" = {
        hostPath = flacLibrary;
        isReadOnly = true;
      };

      # Soulseek credentials from agenix. systemd reads the environmentFile as
      # root before dropping to the slskd user.
      "${credentialsPath}" = {
        hostPath = credentialsPath;
        isReadOnly = true;
      };
    };

    config =
      { config, ... }:
      {
        # Pull the slskd module and package from unstable, replacing the
        # stable module of the same path.
        disabledModules = [
          "services/web-apps/slskd.nix"
        ];

        imports = [
          flake.nixosModules.modules.services.journald
          "${unstable.path}/nixos/modules/services/web-apps/slskd.nix"
        ];

        system.stateVersion = "26.05";
        environment.etc."machine-id".text = "968550ca92ef428e91a8bcb33490d815";
        # Public resolver (unbound's own upstream), not antigone's unbound:
        # the container has no access to the host's resolver or the
        # internal DNS view. resolvconf only compiles dhcp-style sources,
        # which this static container has none of, and falls back to
        # loopback; disabled, and nothing else manages the file, so it is a
        # static etc entry.
        networking.resolvconf.enable = false;
        environment.etc."resolv.conf".text = ''
          nameserver 9.9.9.9
          nameserver 149.112.112.112
        '';

        # The namespace's own firewall: the DNAT'd Soulseek port, and the
        # web UI for nginx.
        networking.firewall.allowedTCPPorts = [
          config.services.slskd.settings.soulseek.listen_port
          config.services.slskd.settings.web.port
        ];

        # Pin slskd's uid so its bind-mounted state stays owned by it across
        # restarts of the ephemeral container, and add it to storage-music so
        # it can read the group-owned FLAC library it shares.
        users.users.slskd = {
          uid = slskdUid;
          extraGroups = [ "storage-music" ];
        };
        users.groups.slskd.gid = slskdGid;
        users.groups.storage-music.gid = storageMusicGid;

        services.journald.settings = {
          SystemMaxUse = "256M";
          SystemMaxFileSize = "32M";
          MaxRetentionSec = "1month";
        };

        # slskd's download dirs are in the service's ReadWritePaths, which
        # systemd requires to exist before it builds the sandbox (slskd can't
        # create them itself, as it never starts). complete/ is world-readable
        # so tancredi's beets can copy-import from it; incomplete/ stays private.
        systemd.tmpfiles.rules = [
          "d ${completeDownloadsDir} 0755 slskd slskd -"
          "d ${incompleteDownloadsDir} 0700 slskd slskd -"
        ];

        services.slskd = {
          enable = true;
          package = unstable.slskd;
          environmentFile = credentialsPath;
          settings = {
            # Bind the web UI to the veth; only nginx's explicit forward
            # rule reaches it.
            web.ip_address = slskdAddress;
            # No web login: the LAN is trusted and nginx fronts it.
            web.authentication.disabled = true;
            # Share the FLAC library (bound read-only) on the Soulseek network.
            shares.directories = [ flacLibrary ];
            # Completed and in-progress files as sibling dirs on the one
            # storage mount (bound above), so finishing a download is a rename
            # within the dataset, not a cross-dataset or cross-pool copy.
            directories.downloads = completeDownloadsDir;
            directories.incomplete = incompleteDownloadsDir;
          };
        };
      };
  };
}
