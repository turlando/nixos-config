{ system, pkgs, ... }@inputs:

let
  # Build the Terranix-generated config at script-build time. The
  # store path is interpolated below as a literal, so running the
  # script does no nix evaluation — it just copies the frozen JSON
  # into place. When infra/configuration.nix changes, this derivation
  # rebuilds, and `nix run .#infra-build` picks up the new path on
  # the next invocation.
  tfConfig = import ../infra (inputs // { inherit system; });
in

pkgs.writeShellApplication {
  name = "infra-build";
  text = ''
    INFRA_DIR="''${INFRA_DIR:-$PWD/infra}"

    if [ ! -d "$INFRA_DIR" ]; then
      echo "Error: $INFRA_DIR does not exist." >&2
      echo "Run from the repo root, or set INFRA_DIR." >&2
      exit 1
    fi

    install -m660 "${tfConfig}" "$INFRA_DIR/config.tf.json"
  '';
}
