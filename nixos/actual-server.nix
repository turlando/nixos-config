{ lib, pkgs, config, ... }:

let
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) types;

  cfg = config.services.actual-server;

  cfgFile = pkgs.writeText "config.json" (builtins.toJSON {
    dataDir = cfg.dataDir;
    hostname = cfg.hostname;
    port = cfg.port;
    serverFiles = "${cfg.dataDir}/server-files";
    userFiles = "${cfg.dataDir}/user-files";
  });
in

{
  options.services.actual-server = {
    enable = mkEnableOption "actual-server";

    package = mkPackageOption pkgs "actual-server" {};

    dataDir = mkOption {
      type = types.str;
      description = ""; # TODO: add description
      default = "/var/lib/actual-server";
    };

    hostname = mkOption {
      type = types.str;
      description = ""; # TODO: add description
      default = "127.0.0.1";
    };

    port = mkOption {
      type = types.port;
      description = ""; # TODO: add description
      default = 5006;
    };
  };

  config = mkIf cfg.enable {
    users.users.actual = {
      name = "actual";
      group = "actual";
      isSystemUser = true;
    };

    users.groups.actual = {};

    systemd.services.actual-server = {
      description = "Actual budget server";
      documentation = [ "https://actualbudget.org/docs/" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/actual";
        Restart = "always";
        User = "actual";
        Group = "actual";
        PrivateTmp = true;
      };
      environment.ACTUAL_CONFIG_PATH = "${cfgFile}";
    };
  };
}
