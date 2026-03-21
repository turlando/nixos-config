{ pkgs, ... }:

{
  services.pcscd.enable = true;
  services.pcscd.plugins = [ pkgs.ccid pkgs.opensc ];

  environment.systemPackages = [
    pkgs.opensc      # PKCS#11 module and tools
    pkgs.pcsc-tools  # pcsc_scan for diagnostics
  ];
}
