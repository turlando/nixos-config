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

  mkTmpfilesRules = path:
    let
      sourcePath = "${cfg.stateDir}${path}";
      parentDir = builtins.dirOf sourcePath;
    in [
      "d ${parentDir} 0755 root root -"
      "d ${sourcePath} 0755 root root -"
    ];
in {
  options.environment.persistence = {
    enable = mkEnableOption "file preservation system";

    stateDir = mkOption {
      type = types.path;
      description = "Directory where preserved files are stored.";
      default = "/var/state";
    };

    paths = mkOption {
      type = types.listOf types.str;
      description = ''
        List of paths to preserve by bind mounting from stateDir.
      '';
      default = [];
      example = [ "/etc/machine-id" "/etc/ssh" "/var/lib/bluetooth" ];
    };
  };

  config = mkIf cfg.enable {
    # Ensure that the persistent storage directory hierarchy exists at boot.
    # Tmpfiles creates both cfg.stateDir and all parent directories for each
    # persisted path before systemd processes the bind mounts. Without these
    # rules, bind mounts may fail because their source paths do not exist yet.
    systemd.tmpfiles.rules =
      [ "d ${cfg.stateDir} 0755 root root -" ]
      ++ lib.lists.unique (lib.concatMap mkTmpfilesRules cfg.paths);

    # Bind mounts redirect the listed paths to their persistent counterparts
    # under cfg.stateDir. systemd.mount units then mount cfg.stateDir + path
    # over the original path early in the boot process. However, systemd does
    # NOT create the source directories automatically; they must already exist.
    fileSystems = builtins.listToAttrs (builtins.map mkBindMount cfg.paths);
  };
}
