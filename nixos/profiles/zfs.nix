{ pkgs, ... }:
{
  boot.zfs.package = pkgs.zfs_2_4;

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
}
