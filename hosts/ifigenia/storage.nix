{ config, ... }:

{
  storage.pools = {
    system = {
      datasets = {
        "root" = { mountPoint = "/"; };
        "nix" = { mountPoint = "/nix"; };
        "state" = { mountPoint = "/var/state"; };
        "home" = { mountPoint = null; };
        "home/tancredi" = { mountPoint = "/home/tancredi"; };
        "swap" = { mountPoint = null; };
      };
    };
  };

  swapDevices = [
    { device = "/dev/zvol/system/swap"; }
  ];
}
