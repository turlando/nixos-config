{ self, system, pkgs, agenix, ... }:

pkgs.writeShellApplication {
  name = "age-passwd";
  meta.description = "Prompt for a password and store its sha-512 hash as an agenix secret";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.mkpasswd
    agenix.packages.${system}.default
  ];
  text = ''
    # Usage check: <name> is required, [identity-file] is optional.
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
      echo "Usage: age-passwd <name> [identity-file]" >&2
      exit 2
    fi

    NAME="$1"

    # Bash and Nix both use ''${...} syntax. Inside this Nix indented
    # string we disambiguate with the Nix escape: prefix the dollar
    # with two single quotes to emit a literal $ for bash. Without
    # that prefix, Nix substitutes the value at build time.
    #
    # Below, the outer ''${2:-...} reaches bash unchanged (escaped);
    # the inner ''${...} is replaced by Nix with the agenix path.
    # Compiled bash: IDENTITY="''${2:-/etc/agenix/key}"
    IDENTITY="''${2:-${self.lib.age.identityFile}}"

    # Where to find secrets.nix and the .age files. Defaults to the
    # `secrets` subdirectory of the cwd (typical when invoked from the
    # repo root); overridable via the SECRETS_DIR env var.
    SECRETS_DIR="''${SECRETS_DIR:-$PWD/secrets}"

    if [ ! -f "$SECRETS_DIR/secrets.nix" ]; then
      echo "Error: $SECRETS_DIR/secrets.nix not found." >&2
      echo "Run from the repo root, or set SECRETS_DIR." >&2
      exit 1
    fi

    AGE_KEY=$(realpath "$IDENTITY")
    AGE_FILE="user-password-$NAME.age"

    printf 'Enter password for %s: ' "$AGE_FILE"
    # -s: silent (no echo); -r: no backslash interpretation.
    read -rs PASSWORD
    echo  # newline after the silent prompt
    if [ -z "$PASSWORD" ]; then
      echo "Error: password must not be empty" >&2
      exit 1
    fi

    # printf '%s' (not echo) to avoid appending a trailing newline that
    # could be hashed together with the password by stricter mkpasswd
    # implementations.
    HASH=$(printf '%s' "$PASSWORD" | mkpasswd -m sha-512 -s)

    # agenix --edit reads new file content from stdin when stdin is not
    # a TTY. The trailing \n matches the convention used by editors
    # writing the decrypted file back.
    cd "$SECRETS_DIR"
    printf '%s\n' "$HASH" | agenix --identity "$AGE_KEY" --edit "$AGE_FILE"
  '';
}
