{ pkgs, ... }:

{

  fonts.fontconfig.enable = true;

  # Enable Bluetooth headsets buttons support.
  services.mpris-proxy.enable = true;

  programs.keepassxc.enable = true;

  home.packages = [
    pkgs.source-code-pro
  ];
}
