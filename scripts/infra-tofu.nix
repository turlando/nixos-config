{ pkgs, pkgs-unstable, ... }@args:

let
  age-read = import ./age-read.nix args;
in

pkgs.writeShellApplication {
  name = "infra-tofu";
  meta.description = "Run tofu against the infra config, decrypting the Hetzner API token first";
  runtimeInputs = [
    (pkgs-unstable.opentofu.withPlugins (p: [ p.hetznercloud_hcloud ]))
    age-read
  ];
  text = ''
    if [ "$#" -lt 1 ]; then
      echo "Usage: infra-tofu <subcommand> [args...]" >&2
      echo "  Decrypts the Hetzner API token from secrets/, then runs" >&2
      echo "  tofu in ./infra with the token as the" >&2
      echo "  hetzner_token_personal variable." >&2
      exit 2
    fi

    INFRA_DIR="''${INFRA_DIR:-$PWD/infra}"

    if [ ! -f "$INFRA_DIR/config.tf.json" ]; then
      echo "Error: $INFRA_DIR/config.tf.json not found." >&2
      echo "Run \`just infra-build\` first." >&2
      exit 1
    fi

    HETZNER_TOKEN_PERSONAL=$(age-read hetzner-api-token-personal)

    tofu -chdir="$INFRA_DIR" "$@" \
      -var="hetzner_token_personal=$HETZNER_TOKEN_PERSONAL"
  '';
}
