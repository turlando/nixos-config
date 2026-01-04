#!/usr/bin/env just

set quiet := true

AGENIX := "agenix"
DEADNIX := "deadnix"
DISKO := "disko"
HOME_MANAGER := "home-manager"
JUST := "just"
MKPASSWD := "mkpasswd"
NIX := "nix"
NIX_GC := "nix-collect-garbage"
NIXOS_GENERATE_CONFIG := "nixos-generate-config"
NIXOS_INSTALL := "nixos-install"
NIXOS_REBUILD := "nixos-rebuild"
STATIX := "statix"

AGENIX_IDENTITY := "/etc/agenix/key"
AGENIX_NIXOS_SECRETS_DIR := "nixos/secrets"
AGENIX_HOME_SECRETS_DIR := "home-manager/secrets"

HOSTNAME := `hostname`
USER := `whoami`

# List all available recipes
default:
  {{JUST}} --list

# Update flake inputs to latest versions
[group("flake")]
update:
    {{NIX}} flake update

# Check flake for errors
[group("flake")]
check:
    {{DEADNIX}}
    {{STATIX}} check

# Remove Nix store generations older than specified time
[group("nix")]
clean older_than="30d":
    {{NIX_GC}} --delete-older-than {{older_than}}

# Remove all old Nix store generations
[group("nix")]
clean-all:
    {{NIX_GC}} --delete-old

[group("nixos")]
nixos-generate-config host=HOSTNAME:
    {{NIXOS_GENERATE_CONFIG}} --no-filesystems --show-hardware-config \
        > "hosts/{{host}}/hardware.nix"

# Install NixOS
[group("nixos")]
nixos-install host:
    # You should run this run after properly setting up the system which usually
    # requires the following stages:
    #   - disko-wipe
    #   - agenix-install-key
    #   - nixos-generate-config
    {{NIXOS_INSTALL}} --flake .#{{host}} --root /mnt --no-root-password

# Build NixOS configuration without activating
[group("nixos")]
nixos-build host=HOSTNAME:
    {{NIX}} build '.#nixosConfigurations.{{host}}.config.system.build.toplevel'

# Build and activate NixOS configuration
[group("nixos")]
nixos-switch host=HOSTNAME:
    {{NIXOS_REBUILD}} switch --flake .#{{host}}

# Build home-manager configuration without activating
[group("home-manager")]
home-build host=HOSTNAME user=USER:
    {{HOME_MANAGER}} build --flake .#{{user}}@{{host}}

# Build and activate home-manager configuration
[group("home-manager")]
home-switch host=HOSTNAME user=USER:
    {{HOME_MANAGER}} switch --flake .#{{user}}@{{host}}

# Destroy existing partitions, format, and mount disks
[group("disko")]
disko-wipe host=HOSTNAME:
    {{DISKO}} --flake '.#{{host}}' --mode destroy,format,mount --yes-wipe-all-disks

# Format and mount disks without destroying existing partitions
[group("disko")]
disko-apply host=HOSTNAME:
    {{DISKO}} --flake '.#{{host}}' --mode format,mount

# Internal: Edit an age-encrypted secret file
[group("agenix")]
_agenix-edit dir name:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{dir}}"
    {{AGENIX}} --identity {{AGENIX_IDENTITY}} --edit "{{name}}.age"

# Install agenix key to /mnt during system installation
[group("agenix")]
agenix-install-key key_dir dest="/mnt/etc/agenix":
    #!/usr/bin/env bash
    # Usage: just agenix-install-key /path/to/agenix-key-directory
    # The directory should contain 'key' and 'key.pub' files
    set -euo pipefail
    if [[ ! -f "{{key_dir}}/key" ]] || [[ ! -f "{{key_dir}}/key.pub" ]]; then
        echo "Error: {{key_dir}} must contain both 'key' and 'key.pub' files"
        exit 1
    fi
    mkdir -p "{{dest}}"
    install -m 600 "{{key_dir}}/key" "{{dest}}/key"
    install -m 644 "{{key_dir}}/key.pub" "{{dest}}/key.pub"

# Edit a NixOS system secret
[group("agenix")]
agenix-nixos-edit name:
    @just _agenix-edit {{AGENIX_NIXOS_SECRETS_DIR}} {{name}}

# Edit a home-manager user secret
[group("agenix")]
agenix-home-edit name:
    @just _agenix-edit {{AGENIX_HOME_SECRETS_DIR}} {{name}}

# Set or update a user password
[group("agenix")]
agenix-passwd user:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{AGENIX_NIXOS_SECRETS_DIR}}"
    echo -n "Enter password for {{user}}: "
    read -s password
    echo
    hash=$(echo "$password" | {{MKPASSWD}} -m sha-512 -s)
    echo "$hash" | {{AGENIX}} --identity {{AGENIX_IDENTITY}} --edit "users-{{user}}-password.age"
