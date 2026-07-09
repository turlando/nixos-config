{ lib, ... }:

let
  inherit (lib) mkOption types;

  ids = import ../../../registry/ids.nix;

  description = ''
    Registry of statically pinned UIDs/GIDs we assign ourselves, for
    identities that must stay stable and identical across the nspawn
    container boundary (containers run privateUsers = false, so a
    container's numeric IDs are the host's).

    This is distinct from nixpkgs' own config.ids, which we reuse where it
    already assigns a service (e.g. syncthing = 237). We only pin what
    nixpkgs leaves dynamic and what has to line up host-side.

    This module is only the accessor: the values live in registry/ids.nix.
    Host and container configs pin their users/groups to these, e.g.
    users.users.slskd.uid = config.environment.ids.uids.slskd.
  '';
in
{
  options.environment.ids = {
    uids = mkOption {
      type = types.attrsOf types.int;
      readOnly = true;
      default = ids.uids;
      inherit description;
    };

    gids = mkOption {
      type = types.attrsOf types.int;
      readOnly = true;
      default = ids.gids;
      inherit description;
    };
  };
}
