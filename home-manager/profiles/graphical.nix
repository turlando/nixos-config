{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  # Enable Bluetooth headsets buttons support.
  services.mpris-proxy.enable = true;

  programs.keepassxc.enable = true;

  home.packages = [
    pkgs.source-code-pro
    pkgs.libreoffice-qt6-fresh
    pkgs.hunspell
    pkgs.hunspellDicts.en-us
    pkgs.hunspellDicts.it-it
  ];
}
