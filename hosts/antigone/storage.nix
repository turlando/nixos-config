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
    storage = {
      datasets = {
        "books" = { mountPoint = "/mnt/storage/books"; };
        "papers" = { mountPoint = "/mnt/storage/papers"; };
        "music" = { mountPoint = null; };
        "music/electronic" = { mountPoint = "/mnt/storage/music/electronic"; };
      };
    };
    scratch = {
      datasets = {
        "downloads" = { mountPoint = null; };
        "downloads/slskd" = { mountPoint = null; };
        "music-mp3" = { mountPoint = null; };
        "music-mp3/electronic" = { mountPoint = "/mnt/scratch/music-mp3/electronic"; };
        "music-opus" = { mountPoint = null; };
        "music-opus/electronic" = { mountPoint = "/mnt/scratch/music-opus/electronic"; };
      };
    };
    backup = { datasets = { }; };
  };
}
