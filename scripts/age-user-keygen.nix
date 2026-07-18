{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "age-user-keygen";
  meta.description = "Generate an age identity for a new agenix user";
  runtimeInputs = [
    pkgs.age
  ];
  text = ''
    if [ "$#" -ne 1 ]; then
      echo "Usage: age-user-keygen <name>" >&2
      echo "  Generate <name>.agekey (an age identity) in the cwd and print" >&2
      echo "  the public half for registry/age-keys.nix (<host>.users.<user>)." >&2
      exit 2
    fi

    NAME="$1"

    ( umask 077; age-keygen -o "''${NAME}.agekey" )
    echo "Add this public key to registry/age-keys.nix under <host>.users.<user>:"
    age-keygen -y "''${NAME}.agekey"
  '';
}
