{ config, lib, pkgs, ... }:

let
  isSupportedFilesystem = x: let
    fs = config.boot.supportedFilesystems;
  in
    if lib.isList fs then
      builtins.elem x fs
    else if lib.isAttrs fs then
      builtins.hasAttr x fs
    else
      false;
in {
  config = lib.mkMerge [
    {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = 10;
      boot.loader.efi.canTouchEfiVariables = false;

      boot.kernelPackages = pkgs.linuxPackages_6_15;
      boot.initrd.systemd.enable = true;
      boot.tmp.useTmpfs = true;

      users.mutableUsers = false;

      security.polkit.enable = true;
      security.run0.enable = true;

      services.fwupd.enable = true;

      programs.zsh.enable = true;
      programs.zsh.promptInit = "";
      programs.zsh.interactiveShellInit = ''
        source ${pkgs.grml-zsh-config}/etc/zsh/zshrc
      '';

      programs.neovim.enable = true;
      programs.neovim.defaultEditor = true;
      programs.git.enable = true;
    }

    (lib.mkIf (isSupportedFilesystem "zfs") {
      services.zfs.autoScrub.enable = true;
      services.zfs.trim.enable = true;
    })
  ];
}
