{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    getExe
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
  ;

  cfg = config.services.actual;
  configFile = pkgs.writeText "config.json" (builtins.toJSON {
    hostname = cfg.hostname;
    port = cfg.port;
    serverFiles = "${cfg.dataDir}/server-files";
    userFiles = "${cfg.dataDir}/user-files";
  });
in
{
  options.services.actual = {
    enable = mkEnableOption "actual, a privacy focused app for managing your finances";
    package = mkPackageOption pkgs "actual-server" { };

    openFirewall = mkOption {
      default = false;
      type = types.bool;
      description = "Whether to open the firewall for the specified port.";
    };

    hostname = mkOption {
      type = types.str;
      description = "The address to listen on";
      default = "127.0.0.1";
    };

    port = mkOption {
      type = types.port;
      description = "The port to listen on";
      default = 3000;
    };

    dataDir = mkOption {
      type = types.str;
      description = ""; # TODO: add description
      default = "/var/lib/actual";
    };
  };

  config = mkIf cfg.enable {
    users.users.actual = {
      name = "actual";
      group = "actual";
      isSystemUser = true;
    };

    users.groups.actual = {};

    networking.firewall.allowedTCPPorts =
      mkIf cfg.openFirewall [ cfg.settings.port ];

    systemd.services.actual = {
      description = "Actual server, a local-first personal finance app";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment.ACTUAL_CONFIG_PATH = configFile;
      serviceConfig = {
        ExecStart = getExe cfg.package;
        User = "actual";
        Group = "actual";
        StateDirectory = cfg.dataDir;
        WorkingDirectory = cfg.dataDir;
        LimitNOFILE = "1048576";
        PrivateTmp = true;
        PrivateDevices = true;
        StateDirectoryMode = "0700";
        Restart = "always";

        # Hardening
        CapabilityBoundingSet = "";
        LockPersonality = true;
        #MemoryDenyWriteExecute = true; # Leads to coredump because V8 does JIT
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        #ProtectSystem = "strict";
        ProtectSystem = "full";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "@pkey"
        ];
        UMask = "0077";
      };
    };
  };
}
