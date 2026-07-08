{ self, config, ... }:
let
  # Pinned syncthing TLS identity from agenix; its fingerprint is the device
  # ID in environment.syncthingDeviceIds.antigone. The module's ExecStartPre
  # runs as root and copies these into configDir, so bind-mounting the
  # host-decrypted paths through is enough.
  certPath = config.age.secrets.syncthing-antigone-cert.path;
  keyPath = config.age.secrets.syncthing-antigone-key.path;
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
    };

    config =
      { ... }:
      {
        imports = [
          self.nixosModules.modules.services.journald
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

        # GUI stays on the default loopback (127.0.0.1:8384); nginx fronts it.
        # The MP3 folder, storage-music access, the sync port on wan0, and the
        # device pairing all come with the shares setup.
        services.syncthing = {
          enable = true;
          # Pin the TLS identity (bound in above) so antigone's device ID stays
          # fixed at environment.syncthingDeviceIds.antigone regardless of the
          # data dataset, instead of a fresh auto-generated cert.
          cert = certPath;
          key = keyPath;
          # nginx proxies with the vhost Host header, not localhost, so skip
          # syncthing's host check. It guards browser-local services against
          # DNS rebinding; the GUI here is on antigone's loopback, reached
          # only through nginx from the trusted LAN, where it does not apply.
          settings.gui.insecureSkipHostcheck = true;
        };
      };
  };
}
