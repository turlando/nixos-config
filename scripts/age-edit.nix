{ self, system, pkgs, agenix, ... }:

pkgs.writeShellApplication {
  name = "age-edit";
  runtimeInputs = [
    agenix.packages.${system}.default
  ];
  text = ''
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
      echo "Usage: age-edit <name> [identity-file]" >&2
      echo "  Decrypt secrets/<name>.age in \$EDITOR; re-encrypt on save." >&2
      exit 2
    fi

    NAME="$1"
    IDENTITY="''${2:-${self.lib.age.identityFile}}"
    SECRETS_DIR="''${SECRETS_DIR:-$PWD/secrets}"

    if [ ! -f "$SECRETS_DIR/secrets.nix" ]; then
      echo "Error: $SECRETS_DIR/secrets.nix not found." >&2
      echo "Run from the repo root, or set SECRETS_DIR." >&2
      exit 1
    fi

    cd "$SECRETS_DIR"
    agenix --identity "$IDENTITY" --edit "$NAME.age"
  '';
}
