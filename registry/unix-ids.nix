# Statically pinned uids/gids we assign ourselves, keyed by name. Public data,
# not secret, surfaced by the environment.unixIds accessor. We only pin what
# nixpkgs leaves dynamic and what has to line up host-side across the nspawn
# container boundary (containers run privateUsers = false, so a container's
# numeric IDs are the host's).
{
  uids = {
    # slskd is newer than nixpkgs' static id list and its module uses a dynamic
    # isSystemUser uid; pinned so its persistent state survives restarts of the
    # ephemeral container.
    slskd = 60001;
  };

  gids = {
    # slskd's primary group, pinned (matching its uid) so its state isn't left
    # group-owned by whatever host group happens to share slskd's
    # otherwise-dynamic gid.
    slskd = 60001;
    # Owns the shared music datasets; the one group that has to be identical on
    # the host and inside the slskd/syncthing containers.
    storage-music = 61001;
  };
}
