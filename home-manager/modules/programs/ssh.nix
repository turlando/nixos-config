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
    gitlab-luminovo.enable = mkEnableOption "";
  };

  # Used to be true by default. Deprecated in Home Manager 25.11 and will be
  # removed in the future.
  config.programs.ssh.enableDefaultConfig = false;

  config.programs.ssh.matchBlocks = mkMerge [
    # The enabled-by-default programs.ssh.enableDefaultConfig option has been
    # deprecated in Home Manager 25.11. In order to keep the old behavior we
    # need this block.
    {
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
    }

    (mkIf cfg.antigone.enable {
      "antigone" = {
        hostname = "81.56.74.151";
        port = 13022;
        user = "tancredi";
        identityFile = config.age.secrets.ssh-key-antigone-tancredi.path;
      };
    })

    (mkIf cfg.github.enable {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = config.age.secrets.ssh-key-github.path;
      };
    })

    (mkIf cfg.gitlab-luminovo.enable {
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = config.age.secrets.ssh-key-luminovo-gitlab.path;
      };
    })

    (mkIf cfg.compiler4-luminovo.enable {
      "compiler4.luminovo.com" = {
        hostname = "148.251.132.243";
        user = "tancredi";
        identityFile = config.age.secrets.ssh-key-luminovo-compilers.path;
      };
    })
  ];
}
