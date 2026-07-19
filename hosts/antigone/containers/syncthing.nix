{ flake, config, ... }:
let
  # Pinned syncthing TLS identity from agenix; its fingerprint is the device
  # ID in environment.syncthing.devices.antigone. The module's ExecStartPre
  # runs as root and copies these into configDir, so bind-mounting the
  # host-decrypted paths through is enough.
  certPath = config.age.secrets.syncthing-antigone-cert.path;
  keyPath = config.age.secrets.syncthing-antigone-key.path;

  # Syncthing's TCP + QUIC sync port.
  syncPort = 22000;

  # MP3 export shared one-way to medea; syncthing joins storage-music to read it.
  mp3Library = config.disko.devices.zpool.storage.datasets."music/electronic-mp3".mountpoint;
  storageMusicGid = config.environment.unixIds.gids.storage-music;

  # Private network namespace addressing: the container's veth peers with
  # antigone's shared services-side address.
  syncthingAddress = config.environment.network.hosts.antigone-syncthing.interfaces.svc0.address;
  servicesGateway = config.environment.network.hosts.antigone.interfaces.svc0.address;

  # Syncthing's GUI port, proxied by nginx.
  guiPort = 8384;
in
{
  disko.devices.zpool.antigone.datasets = {
    "containers/syncthing" = {
      type = "zfs_fs";
      options = {
        canmount = "off";
      };
    };

    "containers/syncthing/journal" = {
      type = "zfs_fs";
      mountpoint = "/var/containers/syncthing/journal";
      options = {
        recordsize = "16K";
        primarycache = "metadata";
        sync = "disabled";
        atime = "off";
      };
    };

    "containers/syncthing/data" = {
      type = "zfs_fs";
      mountpoint = "/var/containers/syncthing/data";
      options = {
        atime = "off";
      };
    };
  };

  # The sync port on the internet edge via DNAT (the forward chain accepts
  # DNAT'd flows); LAN and VPN peers sync directly against the container's
  # routed address, and syncthing dials discovery and relays out through the
  # masqueraded services range. The GUI binds the veth and is reached only
  # through nginx's forward rule.
  networking.nat.forwardPorts = [
    {
      sourcePort = syncPort;
      proto = "tcp";
      destination = "${syncthingAddress}:${toString syncPort}";
    }
    {
      sourcePort = syncPort;
      proto = "udp";
      destination = "${syncthingAddress}:${toString syncPort}";
    }
  ];
  networking.nat.internalIPs = [ "${syncthingAddress}/32" ];
  networking.firewall.extraForwardRules = ''
    iifname { "lan0", "wg0" } oifname "ve-syncthing" tcp dport ${toString syncPort} accept
    iifname { "lan0", "wg0" } oifname "ve-syncthing" udp dport ${toString syncPort} accept
  '';

  # The MP3 dataset is on the storage pool (late stage-2 mount), so order the
  # container after zfs-mount, as slskd does.
  systemd.services."container@syncthing" = {
    after = [ "zfs-mount.service" ];
    requires = [ "zfs-mount.service" ];
  };

  containers.syncthing = {
    ephemeral = true;
    autoStart = true;

    # Own network namespace: the container sees only its veth. nspawn's
    # resolv.conf handling is off, as it would bind the host's (which points
    # at loopback, container-local here); the container writes its own.
    privateNetwork = true;
    hostAddress = servicesGateway;
    localAddress = syncthingAddress;
    extraFlags = [ "--resolv-conf=off" ];

    bindMounts = {
      "/var/log/journal" = {
        hostPath = config.disko.devices.zpool.antigone.datasets
          ."containers/syncthing/journal".mountpoint;
        isReadOnly = false;
      };

      "/var/lib/syncthing" = {
        hostPath = config.disko.devices.zpool.antigone.datasets
          ."containers/syncthing/data".mountpoint;
        isReadOnly = false;
      };

      # Pinned TLS identity from agenix; the module copies it into configDir.
      "${certPath}" = {
        hostPath = certPath;
        isReadOnly = true;
      };

      "${keyPath}" = {
        hostPath = keyPath;
        isReadOnly = true;
      };

      # MP3 export on storage, read-write so syncthing can manage the folder.
      "${mp3Library}" = {
        hostPath = mp3Library;
        isReadOnly = false;
      };
    };

    config =
      { ... }:
      {
        imports = [
          flake.nixosModules.modules.services.journald
        ];

        system.stateVersion = "26.05";
        # A fixed machine-id keeps the persistent journal (bind-mounted above)
        # coherent across restarts of the ephemeral container.
        environment.etc."machine-id".text = "09b948e9b51f452aa5b0fa62196d0145";
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

        # The namespace's own firewall: the sync port, and the GUI for
        # nginx.
        networking.firewall.allowedTCPPorts = [ syncPort guiPort ];
        networking.firewall.allowedUDPPorts = [ syncPort ];

        services.journald.settings = {
          SystemMaxUse = "256M";
          SystemMaxFileSize = "32M";
          MaxRetentionSec = "1month";
        };

        # syncthing (uid 237 from nixpkgs) joins storage-music to read and
        # write the MP3 dataset it shares.
        users.users.syncthing.extraGroups = [ "storage-music" ];
        users.groups.storage-music.gid = storageMusicGid;

        # GUI binds the veth; only nginx's explicit forward rule reaches it.
        services.syncthing = {
          enable = true;
          guiAddress = "${syncthingAddress}:${toString guiPort}";
          # Pin the TLS identity (bound in above) so antigone's device ID stays
          # fixed at environment.syncthing.devices.antigone regardless of the
          # data dataset, instead of a fresh auto-generated cert.
          cert = certPath;
          key = keyPath;
          # nginx proxies with the vhost Host header, not localhost, so skip
          # syncthing's host check. It guards browser-local services against
          # DNS rebinding; the GUI here is on antigone's loopback, reached
          # only through nginx from the trusted LAN, where it does not apply.
          settings.gui.insecureSkipHostcheck = true;

          settings.devices = {
            antigone = config.environment.syncthing.devices.antigone;
            medea = config.environment.syncthing.devices.medea;
          };

          settings.folders."electronic-mp3" = {
            label = "Electronic (MP3)";
            path = mp3Library;
            type = "sendonly";
            devices = [ "medea" ];
          };
        };
      };
  };
}
