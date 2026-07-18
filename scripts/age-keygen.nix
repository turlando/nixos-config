{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "age-keygen";
  meta.description = "Generate an ed25519 SSH keypair for a new agenix host";
  runtimeInputs = [
    pkgs.openssh
  ];
  text = ''
    if [ "$#" -ne 1 ]; then
      echo "Usage: age-keygen <name>" >&2
      echo "  Generate <name>_key (ed25519) in the cwd and print the" >&2
      echo "  public half to stdout." >&2
      exit 2
    fi

    NAME="$1"

    ssh-keygen -t ed25519 -C "$NAME" -f "''${NAME}_key" -N ""
    echo "Add this public key to registry/age-keys.nix:"
    cat "''${NAME}_key.pub"
  '';
}
