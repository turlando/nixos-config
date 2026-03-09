{ config, pkgs-unstable, ... }:
{
  disko.devices.zpool.creusa.datasets = {
    "containers/actual-budget" = {
      type = "zfs_fs";
      options = {
        canmount = "off";
      };
    };

    "containers/actual-budget/journal" = {
      type = "zfs_fs";
      mountpoint = "/var/containers/actual-budget/journal";
      options = {
        recordsize = "16K";
        logbias = "latency";
        primarycache = "metadata";
        sync = "disabled";
        atime = "off";
      };
    };

    "containers/actual-budget/data" = {
      type = "zfs_fs";
      mountpoint = "/var/containers/actual-budget/data";
    };
  };

  services.sanoid = {
    enable = true;
    datasets."creusa/containers/actual-budget/data" = {
      autosnap = true;
      autoprune = true;
      yearly = 0;
      monthly = 0;
      daily = 30;
      hourly = 0;
      frequently = 0;
    };
  };

  containers.actual-budget = {
    ephemeral = true;
    autoStart = true;
    extraFlags = [ "--resolv-conf=bind-host" ];

    bindMounts = {
      "/var/log/journal" = {
        hostPath = config.disko.devices.zpool.creusa.datasets
          ."containers/actual-budget/journal".mountpoint;
        isReadOnly = false;
      };

      "/var/lib/actual" = {
        hostPath = config.disko.devices.zpool.creusa.datasets
          ."containers/actual-budget/data".mountpoint;
        isReadOnly = false;
      };
    };

    config =
      { ... }:
      {
        disabledModules = [
          "services/web-apps/actual.nix"
        ];

        imports = [
          "${pkgs-unstable.path}/nixos/modules/services/web-apps/actual.nix"
        ];

        system.stateVersion = "25.11";
        environment.etc."machine-id".text = "849157410a3041bcf9f3427e69af5832";

        users.groups.actual = {};
        users.users.actual = {
          isSystemUser = true;
          group = "actual";
        };

        systemd.tmpfiles.rules = [
          "d /var/lib/actual 0750 actual actual -"
          "d /var/lib/actual/server-files 0750 actual actual -"
          "d /var/lib/actual/user-files 0750 actual actual -"
        ];

        services.actual = {
          enable = true;
          package = pkgs-unstable.actual-server;
          user = "actual";
          group = "actual";
          settings = {
            hostname = "127.0.0.1";
            port = 5000;
          };
        };
      };
  };
}
