{ self, system, pkgs, nixos-anywhere, ... }:

let
  # nixos-anywhere with --extra-files needs the agenix identity placed
  # under the target's persistence stateDir, since the persistence
  # module bind-mounts ''${stateDir}''${keyDir} -> ''${keyDir} at boot.
  # This script assumes the target uses environment.persistence with
  # the default stateDir of /var/state. Today only creusa is installed
  # this way; non-persistence hosts would need a different recipe.
  keyTargetDir = "/var/state${self.lib.age.keyDir}";
in

pkgs.writeShellApplication {
  name = "nixos-install-remote";
  meta.description = "Install NixOS to a remote host via nixos-anywhere, seeding the agenix key";
  runtimeInputs = [
    nixos-anywhere.packages.${system}.default
  ];
  text = ''
    if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
      echo "Usage: nixos-install-remote <host> <identity-key> <user> [remote]" >&2
      echo "  <host>          NixOS configuration name (e.g. creusa)" >&2
      echo "  <identity-key>  path to the agenix identity (private) key" >&2
      echo "  <user>          ssh login user on the target" >&2
      echo "  [remote]        ssh target host (defaults to <host>)" >&2
      exit 2
    fi

    HOST="$1"
    KEY="$2"
    USER="$3"
    REMOTE="''${4:-$HOST}"

    if [ ! -f "$KEY" ]; then
      echo "Error: identity key file not found: $KEY" >&2
      exit 1
    fi

    # Place the agenix key in a temp dir that mirrors the target's
    # filesystem layout. nixos-anywhere copies these files into the
    # target's / via --extra-files. The persistence module then
    # bind-mounts ${keyTargetDir} to ${self.lib.age.keyDir} at boot,
    # so the key lands where agenix expects it.
    TEMP=$(mktemp -d)
    trap 'rm -rf "$TEMP"' EXIT
    install -d -m 755 "$TEMP${keyTargetDir}"
    install -m 600 "$KEY" "$TEMP${keyTargetDir}/key"

    nixos-anywhere \
      --extra-files "$TEMP" \
      --flake ".#$HOST" \
      "$USER@$REMOTE"
  '';
}
