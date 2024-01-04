{ ... }:

{
  imports = [
    ./git.nix
    ./emacs.nix
  ];

  home.stateVersion = "23.11";

  home.username = "tancredi";
  home.homeDirectory = "/home/tancredi";
}
