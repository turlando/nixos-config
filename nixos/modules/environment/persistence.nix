{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.environment.persistence;

  mkBindMount = path: {
    name = path;
    value = {
      device = "${cfg.stateDir}${path}";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };
  };

  mkTmpfilesRule = path: "d ${cfg.stateDir}${path} 0755 root root -";
in {
  options.environment.persistence = {
    enable = mkEnableOption ''
      persistent path preservation via bind mounts.

      When enabled, every directory listed in
      `environment.persistence.paths` is bind-mounted from its
      counterpart under `stateDir`. Combined with an ephemeral root
      filesystem (e.g. `services.ephemeral`), this is what allows a
      stateless NixOS system to "remember" the things that should
      survive a reboot — SSH host keys, machine identity, network
      configuration, service state — even though `/` is rolled back
      every boot.
    '';

    stateDir = mkOption {
      type = types.path;
      default = "/var/state";
      description = ''
        Mount point of the persistent filesystem under which the
        preserved directories are stored. Must be on a filesystem
        that survives boot (i.e. not subject to ephemeral rollback).

        The `stateDir` mount is automatically marked as
        `neededForBoot = true` so the bind mounts can be processed in
        the initrd.
      '';
    };

    paths = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "/etc/ssh"
        "/var/lib/bluetooth"
        "/etc/NetworkManager/system-connections"
      ];
      description = ''
        Absolute directory paths to preserve. Each path is
        bind-mounted from `''${stateDir}''${path}` at boot. The
        source directory is created with mode 0755 owned by
        `root:root` if it does not already exist; missing parent
        directories under `stateDir` are created implicitly by
        systemd-tmpfiles with the same default mode and owner.

        Only directories are supported. To preserve a single file
        (e.g. `/etc/machine-id`), persist its containing directory
        and rely on the writing service to recreate the file.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable;
        message = ''
          environment.persistence requires boot.initrd.systemd.enable = true,
          because the bind mounts are marked neededForBoot.
        '';
      }
      {
        assertion = lib.all (p: lib.hasPrefix "/" p) cfg.paths;
        message = ''
          environment.persistence.paths must contain only absolute paths
          (each entry must start with "/").
        '';
      }
    ];

    # systemd-tmpfiles creates cfg.stateDir at boot, then each
    # bind-mount source under it. Missing intermediate directories are
    # auto-created by systemd-tmpfiles with the same default mode and
    # owner (0755 root:root), so explicit rules for them are not
    # required.
    systemd.tmpfiles.rules =
      [ "d ${cfg.stateDir} 0755 root root -" ]
      ++ lib.lists.unique (map mkTmpfilesRule cfg.paths);

    fileSystems =
      # The stateDir filesystem (e.g. /var/state) must be mounted in
      # the initrd so it is available when the neededForBoot bind
      # mounts are processed. Without this, bind mounts fail because
      # their source paths do not exist yet.
      { ${cfg.stateDir}.neededForBoot = true; }
      //
      # Bind mounts redirect the listed paths to their persistent
      # counterparts under cfg.stateDir. systemd.mount units then
      # mount cfg.stateDir + path over the original path early in the
      # boot process.
      builtins.listToAttrs (map mkBindMount cfg.paths);
  };
}
