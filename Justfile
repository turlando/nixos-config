#!/usr/bin/env just

set quiet := true

AGENIX := "agenix"
DISKO := "disko"
HOME_MANAGER := "home-manager"
JUST := "just"
MKPASSWD := "mkpasswd"
NIX := "nix"
NIX_GC := "nix-collect-garbage"
NIXOS_INSTALL := "nixos-install"
NIXOS_REBUILD := "nixos-rebuild"

AGENIX_IDENTITY := "/etc/agenix/key"
SYSTEM_SECRETS_DIR := "nixos/secrets"
HOME_SECRETS_DIR := "home-manager/secrets"

HOSTNAME := `hostname`
USER := `whoami`

default:
  {{JUST}} --list

[group("flake")]
update:
    {{NIX}} flake update

[group("flake")]
check:
    {{NIX}} flake check

[group("nixos")]
nixos-install host agenix:
    {{DISKO}} --flake '.#{{host}}' --mode destroy,format,mount --yes-wipe-all-disks
    mkdir -p /mnt/etc
    cp -r {{agenix}} /mnt/etc
    {{NIXOS_INSTALL}} --flake .#{{host}} --root /mnt --no-root-password

[group("nixos")]
nixos-build host=HOSTNAME:
    nix build '.#nixosConfigurations.{{host}}.config.system.build.toplevel'

[group("nixos")]
nixos-switch host=HOSTNAME:
    {{NIXOS_REBUILD}} switch --flake .#{{host}}

[group("nixos")]
home-build host=HOSTNAME user=USER:
    {{HOME_MANAGER}} build --flake .#{{user}}@{{host}}

[group("nixos")]
home-switch host=HOSTNAME user=USER:
    {{HOME_MANAGER}} switch --flake .#{{user}}@{{host}}

[group("nixos")]
clean older_than="30d":
    {{NIX_GC}} --delete-older-than $(PERIOD)

[group("nixos")]
clean-all:
    {{NIX_GC}} --delete-old

[group("secrets")]
sys-secret-edit name:
    (                                      \
        cd {{SYSTEM_SECRETS_DIR}};         \
        {{AGENIX}}                         \
            --identity {{AGENIX_IDENTITY}} \
            --edit {{name}}.age            \
    )

[group("secrets")]
sys-password-edit user:
    (                                                     \
        cd {{SYSTEM_SECRETS_DIR}};                        \
        echo -n "Enter password for {{user}}: ";          \
        read -s password;                                 \
        hash=$(                                           \
            echo "$password"                              \
            | {{MKPASSWD}} -m sha-512 -s                  \
        );                                                \
        echo "$hash"                                      \
        | {{AGENIX}}                                      \
            --identity {{AGENIX_IDENTITY}}                \
            --edit users-{{user}}-password.age;           \
        chown tancredi:users users-{{user}}-password.age; \
    )

[group("secrets")]
home-secret-edit name:
    (                                      \
        cd {{HOME_SECRETS_DIR}};           \
        {{AGENIX}}                         \
            --identity {{AGENIX_IDENTITY}} \
            --edit {{name}}.age            \
    )
