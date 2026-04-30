#!/usr/bin/env just
set quiet := true

HOSTNAME := `hostname`
USER := `whoami`

INFRA_DIR := "infra"
SECRETS_DIR := "secrets"
SECRETS_IDENTITY := "/etc/agenix/key"

# List all available recipes
default:
  just --list

# Update flake inputs to latest versions
[group("flake")]
update:
    nix flake update

# Run unit tests via nix-unit
[group("flake")]
test:
    nix-unit --flake .#tests

# Run linters
[group("flake")]
lint:
    deadnix && statix check

# Verify flake outputs build
[group("flake")]
check:
    nix flake check

# Remove Nix store generations older than specified time
[group("nix")]
clean older_than="30d":
    nix-collect-garbage --delete-older-than {{older_than}}

# Remove all old Nix store generations
[group("nix")]
clean-all:
    nix-collect-garbage --delete-old

[group("nixos")]
nixos-generate-config host=HOSTNAME:
    nixos-generate-config --no-filesystems --show-hardware-config \
        > "hosts/{{host}}/hardware.nix"

# Install NixOS
[group("nixos")]
nixos-install host:
    # You should run this run after properly setting up the system which usually
    # requires the following stages:
    #   - disko-wipe
    #   - secrets-install-key
    #   - nixos-generate-config
    nixos-install --flake .#{{host}} --root /mnt --no-root-password


# Deploy NixOS to a new remote host via nixos-anywhere
[group("nixos")]
nixos-install-remote host key remote=host:
    nix run .#nixos-install-remote -- "{{host}}" "{{key}}" "{{remote}}"

# Build NixOS configuration without activating
[group("nixos")]
nixos-build host=HOSTNAME:
    nix build '.#nixosConfigurations.{{host}}.config.system.build.toplevel'

# Build and activate NixOS configuration
[group("nixos")]
nixos-switch host=HOSTNAME:
    nixos-rebuild switch --flake .#{{host}}

# Build and activate NixOS configuration to a remote host
[group("nixos")]
nixos-switch-remote host remote=host user="root":
    nixos-rebuild switch --flake .#{{host}} --target-host root@{{remote}}

# Build home-manager configuration without activating
[group("home-manager")]
home-build host=HOSTNAME user=USER:
    home-manager build --flake .#{{user}}@{{host}}

# Build and activate home-manager configuration
[group("home-manager")]
home-switch host=HOSTNAME user=USER:
    home-manager switch --flake .#{{user}}@{{host}}

# Destroy existing partitions, format, and mount disks
[group("disko")]
disko-wipe host=HOSTNAME:
    disko --flake '.#{{host}}' --mode destroy,format,mount --yes-wipe-all-disks

# Format and mount disks without destroying existing partitions
[group("disko")]
disko-apply host=HOSTNAME:
    disko --flake '.#{{host}}' --mode format,mount

# Apply disko changes (format and mount) on a remote host
[group("disko")]
disko-apply-remote host remote=host:
    nix run .#disko-apply-remote -- "{{host}}" "{{remote}}"

# Generate an SSH ed25519 key pair for a new host
[group("agenix")]
age-keygen name:
    nix run .#age-keygen -- "{{name}}"

# Install agenix key to /mnt during system installation
[group("agenix")]
age-install-key key_dir dest="/mnt/etc/agenix":
    nix run .#age-install-key -- "{{key_dir}}" "{{dest}}"

# Create or edit an age-encrypted secret
[group("agenix")]
age-edit name identity=SECRETS_IDENTITY:
    nix run .#age-edit -- "{{name}}" "{{identity}}"

# Decrypt and print a secret to stdout
[group("agenix")]
age-read name identity=SECRETS_IDENTITY:
    nix run .#age-read -- "{{name}}" "{{identity}}"

# Re-encrypt all secrets with current keys
[group("agenix")]
age-rekey identity=SECRETS_IDENTITY:
    nix run .#age-rekey -- "{{identity}}"

# Set or update a user password
[group("agenix")]
age-passwd name identity=SECRETS_IDENTITY:
    nix run .#age-passwd -- "{{name}}" "{{identity}}"

# Generate Terranix config as Terraform JSON
[group("infra")]
infra-build:
    #!/usr/bin/env bash
    set -euo pipefail
    TF_CONFIG=$(nix build '.#terraform-config' --no-link --print-out-paths)
    install -m660 "$TF_CONFIG" "{{INFRA_DIR}}/config.tf.json"

# Preview infrastructure changes
[group("infra")]
infra-plan: infra-build
    #!/usr/bin/env bash
    set -euo pipefail
    HETZNER_TOKEN_PERSONAL=$(just age-read hetzner-api-token-personal)
    tofu \
        -chdir="{{INFRA_DIR}}" \
        plan \
        -var="hetzner_token_personal=$HETZNER_TOKEN_PERSONAL"

# Apply infrastructure changes
[group("infra")]
infra-apply: infra-build
    #!/usr/bin/env bash
    set -euo pipefail
    HETZNER_TOKEN_PERSONAL=$(just age-read hetzner-api-token-personal)
    tofu \
        -chdir="{{INFRA_DIR}}" \
        apply \
        -var="hetzner_token_personal=$HETZNER_TOKEN_PERSONAL"
