{ self, system, pkgs, agenix, ... }:

pkgs.writeShellApplication {
  name = "age-rekey";
  meta.description = "Re-encrypt all agenix secrets with the current set of public keys";
  runtimeInputs = [
    agenix.packages.${system}.default
  ];
  text = ''
    if [ "$#" -gt 1 ]; then
      echo "Usage: age-rekey [identity-file]" >&2
      echo "  Re-encrypt all secrets in secrets/ with current public keys." >&2
      exit 2
    fi

    IDENTITY="''${1:-${self.lib.age.identityFile}}"
    SECRETS_DIR="''${SECRETS_DIR:-$PWD/secrets}"

    if [ ! -f "$SECRETS_DIR/secrets.nix" ]; then
      echo "Error: $SECRETS_DIR/secrets.nix not found." >&2
      echo "Run from the repo root, or set SECRETS_DIR." >&2
      exit 1
    fi

    cd "$SECRETS_DIR"
    agenix --identity "$IDENTITY" --rekey
  '';
}
