{ flake, pkgs, ... }:

pkgs.writeShellApplication {
  name = "age-install-user-key";
  meta.description = "Install an age identity as a user's agenix key (~/.config/agenix/key)";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.getent
  ];
  text = ''
    if [ "$#" -ne 2 ]; then
      echo "Usage: age-install-user-key <keyfile> <user>" >&2
      echo "  Install <keyfile> as <user>'s agenix identity at their" >&2
      echo "  ~/${flake.lib.age.userKeyFile} (0600, owned by <user>)." >&2
      echo "  Run as root to install for another user." >&2
      exit 2
    fi

    KEYFILE="$1"
    TARGET_USER="$2"

    if [ ! -f "$KEYFILE" ]; then
      echo "Error: key file not found: $KEYFILE" >&2
      exit 1
    fi

    HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    if [ -z "$HOME_DIR" ]; then
      echo "Error: unknown user: $TARGET_USER" >&2
      exit 1
    fi

    install -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" -m 600 -D \
      "$KEYFILE" "$HOME_DIR/${flake.lib.age.userKeyFile}"
    echo "Installed $TARGET_USER identity at $HOME_DIR/${flake.lib.age.userKeyFile}"
  '';
}
