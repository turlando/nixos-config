{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_7_0;
  boot.zfs.package = pkgs.zfs_2_4;

  # `boot.zfs.forceImportRoot` is `true` by default as of NixOS 26.05. Starting
  # from NixOS 26.11 the new default will be `false`. It is highly recommended
  # to set it to `false` to reduce the risk of data loss.
  boot.zfs.forceImportRoot = false;

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
}
