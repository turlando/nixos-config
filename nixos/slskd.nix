{ lib, pkgs, config, ... }:

let
  inherit (lib) mkEnableOption mkOption mkPackageOptionMD types;
in
{
  disabledModules = [ "services/web-apps/slskd.nix" ];

  options.services.slskd = {
    enable = mkEnableOption "enable slskd";

    rotateLogs = mkEnableOption
      "enable an unit and timer that will rotate logs in dataDir/logs";

    package = mkPackageOptionMD pkgs "slskd" { };

    dataDir = mkOption {
      type = types.str;
      description = ""; # TODO: add description;
      default = "/var/lib/slskd";
    };

    configFile = mkOption {
      type = types.str;
      description = "Path to the configuration file.";
      default = "/var/lib/slskd/slskd.yml";
    };
  };

  config = let
    cfg = config.services.slskd;
  in lib.mkIf cfg.enable {
    users = {
      users.slskd = {
        isSystemUser = true;
        group = "slskd";
      };
      groups.slskd = {};
    };

    # Hide state & logs
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/data 0750 slskd slskd - -"
      "d ${cfg.dataDir}/logs 0750 slskd slskd - -"
    ];

    systemd.services.slskd = {
      description = ''
        A modern client-server application for the Soulseek file sharing network
      '';
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "slskd";
        StateDirectory = "slskd";
        ExecStart = ''
          ${cfg.package}/bin/slskd \
              --app-dir ${cfg.dataDir} \
              --config ${cfg.configFile}
        '';
        Restart = "on-failure";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "full";
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
      };
    };

    systemd.services.slskd-rotatelogs = lib.mkIf cfg.rotateLogs {
      description = "Rotate slskd logs";
      serviceConfig = {
        Type = "oneshot";
        User = "slskd";
        ExecStart = [
          ''
            ${pkgs.findutils}/bin/find \
              ${cfg.dataDir}/logs/ -type f -mtime +10 \
              -delete
          ''
          ''
          ${pkgs.findutils}/bin/find \
            ${cfg.dataDir}/logs/ -type f -mtime +1 \
            -exec ${pkgs.gzip}/bin/gzip -q {} ';'
          ''
        ];
      };
      startAt = "daily";
    };
  };
}
