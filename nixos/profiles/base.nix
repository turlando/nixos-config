{ pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.efi.canTouchEfiVariables = false;

  boot.initrd.systemd.enable = true;
  # Allow an (unauthenticated) root shell in the initrd emergency target.
  # It runs before the pool is unlocked, so no encrypted data is exposed;
  # without it a locked root account makes initrd failures undebuggable.
  boot.initrd.systemd.emergencyAccess = true;

  boot.tmp.useTmpfs = true;
  zramSwap.enable = true;

  users.mutableUsers = false;

  programs.zsh.enable = true;
  programs.zsh.promptInit = "";
  programs.zsh.interactiveShellInit = ''
    source ${pkgs.grml-zsh-config}/etc/zsh/zshrc
  '';

  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  programs.git.enable = true;
}
