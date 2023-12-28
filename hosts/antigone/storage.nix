{ config, ... }:

{
  storage.pools = {
    system = {
      datasets = {
        "root" = { mountPoint = "/"; };
        "nix" = { mountPoint = "/nix"; };
        "state" = { mountPoint = "/var/state"; };
        "services" = { mountPoint = null; };
        "services/quassel" = { mountPoint = "/var/services/quassel"; };
        "services/syncting" = { mountPoint = "/var/services/syncthing"; };
        "services/slskd" = { mountPoint = "/var/services/slskd"; };
        "services/podman" = { mountPoint = null; };
        "home" = { mountPoint = null; };
        "home/tancredi" = { mountPoint = "/home/tancredi"; };
      };
    };
  };
}
