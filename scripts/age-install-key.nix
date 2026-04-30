{ self, pkgs, ... }:

let
  # Default install destination. /mnt is the convention during NixOS
  # install (target root mounted at /mnt); ${self.lib.age.keyDir} is
  # the agenix key directory baked in at build time.
  defaultDest = "/mnt${self.lib.age.keyDir}";
in

pkgs.writeShellApplication {
  name = "age-install-key";
  text = ''
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
      echo "Usage: age-install-key <key-dir> [dest]" >&2
      echo "  <key-dir>  directory containing 'key' and 'key.pub'" >&2
      echo "  [dest]     install destination (default: ${defaultDest})" >&2
      exit 2
    fi

    KEY_DIR="$1"
    DEST="''${2:-${defaultDest}}"

    if [ ! -f "$KEY_DIR/key" ] || [ ! -f "$KEY_DIR/key.pub" ]; then
      echo "Error: $KEY_DIR must contain both 'key' and 'key.pub'" >&2
      exit 1
    fi

    mkdir -p "$DEST"
    install -m 600 "$KEY_DIR/key" "$DEST/key"
    install -m 644 "$KEY_DIR/key.pub" "$DEST/key.pub"
  '';
}
