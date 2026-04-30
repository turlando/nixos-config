{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "disko-apply-remote";
  runtimeInputs = [
    pkgs.openssh
  ];
  text = ''
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
      echo "Usage: disko-apply-remote <host> [remote]" >&2
      echo "  <host>    NixOS configuration name" >&2
      echo "  [remote]  ssh target host (defaults to <host>)" >&2
      exit 2
    fi

    HOST="$1"
    REMOTE="''${2:-$HOST}"

    # Build the disko format-mount script locally, copy it to the
    # target's Nix store via SSH, then execute it on the target.
    SCRIPT=$(
      nix build --no-link --print-out-paths                           \
        ".#nixosConfigurations.$HOST.config.system.build.formatMount"
    )

    nix copy --to "ssh://root@$REMOTE" "$SCRIPT"

    # shellcheck disable=SC2029
    # $SCRIPT must expand client-side: it is the local store path of
    # the just-copied derivation, which the remote must invoke verbatim.
    ssh "root@$REMOTE" "$SCRIPT/bin/disko-format-mount"
  '';
}
