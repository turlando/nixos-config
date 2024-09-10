{ config, options, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;
  inherit (lib.files) getSshKey readPassword;
in

{
  options.environment.defaults.enable = mkOption {
    type = types.bool;
    default = false;
    example = true;
  };

  config = mkIf config.environment.defaults.enable {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
      "repl-flake"
    ];

    boot.initrd.systemd.enable = true;
    boot.initrd.systemd.initrdBin = [ pkgs.procps ];

    boot.tmp.useTmpfs = true;

    time.timeZone = "Europe/Rome";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LANGUAGE = "en_US.UTF-8";
      LC_COLLATE = "C.UTF-8";
      LC_IDENTIFICATION = "it_IT.UTF-8";
      LC_MEASUREMENT = "it_IT.UTF-8";
      LC_MESSAGES = "en_US.UTF-8";
      LC_MONETARY = "it_IT.UTF-8";
      LC_NAME = "it_IT.UTF-8";
      LC_NUMERIC = "it_IT.UTF-8";
      LC_PAPER = "it_IT.UTF-8";
      LC_TELEPHONE = "it_IT.UTF-8";
      LC_TIME = "it_IT.UTF-8";
    };

    services.openssh.hostKeys = let
      inherit (lib) mkIf mkMerge;
      inherit (lib.attrsets) updateManyAttrsByPath;
      ephemeral = config.services.ephemeral.enable;
      stateDir = config.environment.state;
      default = options.services.openssh.hostKeys.default;
      new = map
        (attr: updateManyAttrsByPath
          [ {
            path = [ "path" ];
            update = p: "${toString stateDir}/${p}";
          } ]
          attr)
        default;
    in mkIf ephemeral new;

    security.sudo = {
      enable = true;
      extraConfig = ''
        Defaults lecture="never"
      '';
    };

    users = {
      mutableUsers = false;
      users = {
        root = {
          hashedPassword = readPassword "tancredi";
          openssh.authorizedKeys.keyFiles = [ (getSshKey "tancredi") ];
        };
        tancredi = {
          isNormalUser = true;
          hashedPassword = readPassword "tancredi";
          shell = pkgs.zsh;
          extraGroups = [ config.users.groups.wheel.name ];
          openssh.authorizedKeys.keyFiles = [ (getSshKey "tancredi") ];
        };
      };
    };

    environment.systemPackages = with pkgs; [
      pciutils
      usbutils

      smartmontools

      zsh
      grml-zsh-config

      tmux
      gnumake
      git
    ];

    programs = {
      zsh = {
        enable = true;
        promptInit = ""; # unset to use grml prompt
        interactiveShellInit = ''
          source ${pkgs.grml-zsh-config}/etc/zsh/zshrc
        '';
      };
      neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
        defaultEditor = true;
      };
    };
  };
}
