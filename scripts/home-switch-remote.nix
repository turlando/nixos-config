{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "home-switch-remote";
  meta.description = "Build and activate a home-manager configuration on a remote host";
  runtimeInputs = [
    pkgs.nix
    pkgs.openssh
  ];
  text = ''
    if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
      echo "Usage: home-switch-remote <host> <user> [remote] [copy-user]" >&2
      echo "  <host>       home-manager configuration host" >&2
      echo "  <user>       configuration user; activation runs as this user" >&2
      echo "  [remote]     ssh target host (defaults to <host>)" >&2
      echo "  [copy-user]  ssh user for the store copy (defaults to root)" >&2
      exit 2
    fi

    HOST="$1"
    USER="$2"
    REMOTE="''${3:-$HOST}"
    COPYUSER="''${4:-root}"

    # Build only the requested activation package. Unlike disko-apply-remote,
    # which bakes every host's tiny formatMount into the script, home closures
    # are large, so building them all up front (and on every flake check) would
    # be wasteful; build on demand instead.
    REF=".#homeConfigurations.\"$USER@$HOST\".activationPackage"
    ACTIVATION="$(nix build --no-link --print-out-paths "$REF")"

    # Copy the closure as a trusted user (root by default): importing unsigned,
    # locally-built paths requires trust, which the config's unprivileged user
    # usually lacks. Then run the activate script as the configuration's user,
    # into whose home it writes.
    nix copy --to "ssh://$COPYUSER@$REMOTE" "$ACTIVATION"

    # shellcheck disable=SC2029
    # $ACTIVATION must expand client-side: it is the local store path of the
    # just-built package, which the remote invokes verbatim.
    ssh "$USER@$REMOTE" "$ACTIVATION/activate"
  '';
}
