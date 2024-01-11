{ lib, pkgs, config, ... }:

let
  inherit (lib) mkEnableOption mkOption mkPackageOptionMD types;
in
{
  options.services.airdcpp = {
    enable = mkEnableOption "enable airdcpp";

    package = mkPackageOptionMD pkgs "airdcpp" { };

    dataDir = mkOption {
      type = types.str;
      description = ""; # TODO: add description;
      default = "/var/lib/airdcpp";
    };
  };

  config = let
    cfg = config.services.airdcpp;
  in lib.mkIf cfg.enable {
    users = {
      users.airdcpp = {
        isSystemUser = true;
        group = "airdcpp";
      };
      groups.airdcpp = {};
    };

    systemd.services.airdcpp = {
      description = "";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "airdcpp";
        StateDirectory = "airdcpp";
        PIDFile = "/var/lib/airdcpp/airdcppd.pid";
        ExecStart = ''
          ${cfg.package}/bin/airdcppd \
              -c=${cfg.dataDir} \
              -p=/var/lib/airdcpp/airdcppd.pid
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
  };
}
