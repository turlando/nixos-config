{ flake, config, ... }:
let
  # Private network namespace addressing: the container's veth peers with
  # creusa's shared services-side address.
  actualAddress = config.environment.network.hosts.creusa-actual.interfaces.svc0.address;
  servicesGateway = config.environment.network.hosts.creusa.interfaces.svc0.address;

  # actual's HTTP port, proxied by nginx.
  actualPort = 5000;

  unstable = config.nixpkgs.unstable.pkgs;
in
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

  # Named actual, not actual-budget: the private network names the veth
  # ve-<container>, and ve-actual-budget exceeds the kernel's interface
  # name length limit.
  containers.actual = {
    ephemeral = true;
    autoStart = true;

    # Own network namespace: the container sees only its veth. No
    # resolv.conf at all: actual gets no internet egress and resolves
    # nothing.
    privateNetwork = true;
    hostAddress = servicesGateway;
    localAddress = actualAddress;
    extraFlags = [ "--resolv-conf=off" ];

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
          flake.nixosModules.modules.services.journald
          "${unstable.path}/nixos/modules/services/web-apps/actual.nix"
        ];

        system.stateVersion = "26.05";
        environment.etc."machine-id".text = "849157410a3041bcf9f3427e69af5832";

        # No resolver: actual has no egress and resolves nothing. With
        # resolvconf's loopback fallback disabled, resolv.conf is empty
        # rather than pointing at a resolver that does not exist.
        networking.resolvconf.enable = false;

        # The namespace's own firewall: actual's port for nginx.
        networking.firewall.allowedTCPPorts = [ actualPort ];

        services.journald.settings = {
          SystemMaxUse = "256M";
          SystemMaxFileSize = "32M";
          MaxRetentionSec = "1month";
        };

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
          package = unstable.actual-server;
          user = "actual";
          group = "actual";
          settings = {
            # Bind the veth; only nginx's explicit forward rule reaches it.
            hostname = actualAddress;
            port = actualPort;
          };
        };
      };
  };
}
