{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.programs.ssh.hosts;
in
{
  options.programs.ssh.hosts = {
    antigone.enable = mkEnableOption "";
    compiler4-luminovo.enable = mkEnableOption "";
    creusa.enable = mkEnableOption "";
    github.enable = mkEnableOption "";
  };

  config.programs.ssh.matchBlocks = mkMerge [
    (mkIf cfg.antigone.enable {
      "antigone" = {
        hostname = "81.56.74.151";
        port = 13022;
        user = "tancredi";
        identityFile = config.age.secrets.ssh-key-tancredi.path;
      };
    })

    (mkIf cfg.compiler4-luminovo.enable {
      "compiler4.luminovo.com" = {
        hostname = "148.251.132.243";
        user = "tancredi";
        identityFile = config.age.secrets.ssh-key-tancredi.path;
      };
    })

    (mkIf cfg.creusa.enable {
      "creusa" = {
        hostname = "78.47.53.181";
        user = "tancredi";
        identityFile = config.age.secrets.ssh-key-tancredi.path;
      };
    })

    (mkIf cfg.github.enable {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = config.age.secrets.ssh-key-github.path;
      };
    })
  ];
}
