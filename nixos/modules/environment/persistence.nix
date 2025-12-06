{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption types;

  mkBindMount = path: {
    name = path;
    value = {
      device = "${config.environment.persistence.stateDir}${path}";
      fsType = "none";
      options = [ "bind" ];
    };
  };
in {
  options.environment.persistence = {
    enable = mkEnableOption "file preservation system";
    
    stateDir = mkOption {
      type = types.path;
      description = "Directory where preserved files are stored";
      default = "/var/state";
    };
    
    paths = mkOption {
      type = types.listOf types.str;
      description = ''
        List of paths to preserve by bind mounting from stateDir.
      '';
      default = [];
      example = [ "/etc/nixos" "/home/user/.ssh" "/var/lib/bluetooth" ];
    };
  };

  config = let
    cfg = config.environment.persistence;
  in mkIf cfg.enable {
    fileSystems = builtins.listToAttrs (builtins.map mkBindMount cfg.paths);
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 root root -"
    ] ++ (builtins.map
      (path: "d ${cfg.stateDir}${builtins.dirOf path} 0755 root root -")
      cfg.paths);
  };
}
