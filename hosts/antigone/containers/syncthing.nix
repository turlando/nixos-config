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

  # syncthing's sync port on the internet edge (like slskd's P2P port); the GUI
  # stays loopback behind nginx, and local discovery stays on lan0.
  networking.firewall.interfaces.wan0.allowedTCPPorts = [ syncPort ];
  networking.firewall.interfaces.wan0.allowedUDPPorts = [ syncPort ];

  # The MP3 dataset is on the storage pool (late stage-2 mount), so order the
  # container after zfs-mount, as slskd does.
  systemd.services."container@syncthing" = {
    after = [ "zfs-mount.service" ];
    requires = [ "zfs-mount.service" ];
  };

  containers.syncthing = {
    ephemeral = true;
    autoStart = true;
    extraFlags = [ "--resolv-conf=bind-host" ];

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

        services.journald.settings = {
          SystemMaxUse = "256M";
          SystemMaxFileSize = "32M";
          MaxRetentionSec = "1month";
        };

        # syncthing (uid 237 from nixpkgs) joins storage-music to read and
        # write the MP3 dataset it shares.
        users.users.syncthing.extraGroups = [ "storage-music" ];
        users.groups.storage-music.gid = storageMusicGid;

        # GUI stays on the default loopback (127.0.0.1:8384); nginx fronts it.
        services.syncthing = {
          enable = true;
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
