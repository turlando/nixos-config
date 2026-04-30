{ self, pkgs, ... }:

let
  inherit (pkgs) lib;

  # Pre-build formatMount for every nixosConfiguration so the script
  # doesn't need a `nix build` call at runtime. Each host's outPath
  # gets baked into the case statement below as a literal store path.
  formatMountByHost = builtins.mapAttrs
    (_: nixosCfg: nixosCfg.config.system.build.formatMount)
    self.nixosConfigurations;

  caseClauses = lib.concatMapStringsSep "\n  "
    (host: ''${host}) SCRIPT="${formatMountByHost.${host}}" ;;'')
    (lib.attrNames formatMountByHost);
in

pkgs.writeShellApplication {
  name = "disko-apply-remote";
  meta.description = "Format and mount disks on a remote host (non-destructive)";
  runtimeInputs = [ pkgs.openssh ];
  text = ''
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
      echo "Usage: disko-apply-remote <host> [remote]" >&2
      echo "  <host>    NixOS configuration name" >&2
      echo "  [remote]  ssh target host (defaults to <host>)" >&2
      exit 2
    fi

    HOST="$1"
    REMOTE="''${2:-$HOST}"

    # Look up the pre-built formatMount derivation for $HOST. Building
    # this script implicitly builds formatMount for every known host;
    # at runtime no `nix build` call is needed.
    case "$HOST" in
      ${caseClauses}
      *) echo "Error: unknown host: $HOST" >&2; exit 1 ;;
    esac

    # Copy the formatMount derivation to the target's Nix store, then
    # execute it on the target.
    nix copy --to "ssh://root@$REMOTE" "$SCRIPT"

    # shellcheck disable=SC2029
    # $SCRIPT must expand client-side: it is the local store path of
    # the just-copied derivation, which the remote must invoke verbatim.
    ssh "root@$REMOTE" "$SCRIPT/bin/disko-format-mount"
  '';
}
