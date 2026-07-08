{ lib, ... }:

let
  inherit (lib) mkOption types;

  description = ''
    Registry of statically pinned UIDs/GIDs we assign ourselves, for
    identities that must stay stable and identical across the nspawn
    container boundary (containers run privateUsers = false, so a
    container's numeric IDs are the host's).

    This is distinct from nixpkgs' own config.ids, which we reuse where it
    already assigns a service (e.g. syncthing = 237). We only pin what
    nixpkgs leaves dynamic and what has to line up host-side.

    Accessor only: host and container configs pin their users/groups to
    these, e.g. users.users.slskd.uid = config.environment.ids.uids.slskd.
  '';
in
{
  options.environment.ids = {
    uids = mkOption {
      type = types.attrsOf types.int;
      readOnly = true;
      default = {
        # slskd is newer than nixpkgs' static id list and its module uses a
        # dynamic isSystemUser uid; pinned so its persistent state survives
        # restarts of the ephemeral container.
        slskd = 60001;
      };
      inherit description;
    };

    gids = mkOption {
      type = types.attrsOf types.int;
      readOnly = true;
      default = {
        # slskd's primary group, pinned (matching its uid) so its state isn't
        # left group-owned by whatever host group happens to share slskd's
        # otherwise-dynamic gid.
        slskd = 60001;
        # Owns the shared music datasets; the one group that has to be
        # identical on the host and inside the slskd/syncthing containers.
        storage-music = 61001;
      };
      inherit description;
    };
  };
}
