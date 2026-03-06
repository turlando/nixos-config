#!/usr/bin/env just
set quiet := true

HOSTNAME := `hostname`
USER := `whoami`

SECRETS_DIR := "secrets"
SECRETS_IDENTITY := "/etc/agenix/key"

# List all available recipes
default:
  just --list

# Update flake inputs to latest versions
[group("flake")]
update:
    nix flake update

# Run test suite
[group("flake")]
test:
    nix flake check

# Run linters
[group("flake")]
check:
    deadnix
    statix check

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

# Build NixOS configuration without activating
[group("nixos")]
nixos-build host=HOSTNAME:
    nix build '.#nixosConfigurations.{{host}}.config.system.build.toplevel'

# Build and activate NixOS configuration
[group("nixos")]
nixos-switch host=HOSTNAME:
    nixos-rebuild switch --flake .#{{host}}

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

# Generate an SSH ed25519 key pair for a new host
[group("agenix")]
age-keygen name:
    #!/usr/bin/env bash
    set -euo pipefail
    ssh-keygen -t ed25519 -C "{{name}}" -f "{{name}}_key" -N ""
    echo "Add this public key to {{SECRETS_DIR}}/keys.nix:"
    cat "{{name}}_key.pub"

# Install agenix key to /mnt during system installation
[group("agenix")]
age-install-key key_dir dest="/mnt/etc/agenix":
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! -f "{{key_dir}}/key" ]] || [[ ! -f "{{key_dir}}/key.pub" ]]; then
        echo "Error: {{key_dir}} must contain both 'key' and 'key.pub' files"
        exit 1
    fi
    mkdir -p "{{dest}}"
    install -m 600 "{{key_dir}}/key" "{{dest}}/key"
    install -m 644 "{{key_dir}}/key.pub" "{{dest}}/key.pub"

# Create or edit an age-encrypted secret
[group("agenix")]
age-edit name identity=SECRETS_IDENTITY:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{SECRETS_DIR}}"
    agenix --identity {{identity}} --edit "{{name}}.age"

# Decrypt and print a secret to stdout
[group("agenix")]
age-read name identity=SECRETS_IDENTITY:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{SECRETS_DIR}}"
    agenix --identity {{identity}} --decrypt "{{name}}.age"

# Re-encrypt all secrets with current keys
[group("agenix")]
age-rekey identity=SECRETS_IDENTITY:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{SECRETS_DIR}}"
    agenix --identity {{identity}} --rekey

# Set or update a user password
[group("agenix")]
age-passwd name identity=SECRETS_IDENTITY:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{SECRETS_DIR}}"
    AGE_FILE="user-password-{{name}}.age"
    echo -n "Enter password for $AGE_FILE: "
    read -s PASSWORD
    echo
    HASH=$(echo "$PASSWORD" | mkpasswd -m sha-512 -s)
    echo "$HASH" | agenix --identity {{identity}} --edit "$AGE_FILE"
