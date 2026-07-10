let
  keys = import ./keys.nix;
  scope = import ./scope.nix;
in
{
  # Hashed login password for root user on medea.
  "user-password-root.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ nixos ];
  };

  # Hashed login password for tancredi user on medea.
  "user-password-tancredi.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ nixos ];
  };

  # Hashed login password for luminovo user on medea.
  "user-password-medea-luminovo.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ nixos ];
  };

  # Login password for root UNIX user on creusa.
  "user-password-creusa-root.age" = {
    publicKeys = with keys; [ creusa ];
    scope = with scope; [ nixos ];
  };

  # Login password for root UNIX user on antigone.
  "user-password-antigone-root.age" = {
    publicKeys = with keys; [ antigone ];
    scope = with scope; [ nixos ];
  };

  # Login password for tancredi UNIX user on antigone.
  "user-password-antigone-tancredi.age" = {
    publicKeys = with keys; [ antigone ];
    scope = with scope; [ nixos ];
  };

  # ZFS passphrase for the storage pool. Read via keylocation for unattended
  # unlock once the root pool is open; also typeable at a prompt for recovery.
  "zfs-passphrase-storage.age" = {
    publicKeys = with keys; [ antigone ];
    scope = with scope; [ nixos ];
  };

  # Soulseek network credentials for slskd (SLSKD_SLSK_USERNAME /
  # SLSKD_SLSK_PASSWORD), delivered as its environmentFile in the container.
  "slskd-credentials.age" = {
    publicKeys = with keys; [ antigone ];
    scope = with scope; [ nixos ];
  };

  # Syncthing TLS identity for antigone: the cert and key whose fingerprint is
  # the device ID published in registry/syncthing-devices.nix. Delivered into
  # the container as services.syncthing.cert/key.
  "syncthing-antigone-cert.age" = {
    publicKeys = with keys; [ antigone ];
    scope = with scope; [ nixos ];
  };

  "syncthing-antigone-key.age" = {
    publicKeys = with keys; [ antigone ];
    scope = with scope; [ nixos ];
  };

  # Syncthing TLS identity for tancredi@medea's user-level syncthing (scope
  # tancredi: decrypted in the home realm, where the HM service copies it into
  # configDir). Its fingerprint is the medea device ID in
  # registry/syncthing-devices.nix.
  "syncthing-medea-cert.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ tancredi ];
  };

  "syncthing-medea-key.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ tancredi ];
  };

  # Discogs personal access token for tancredi@antigone's beets library curation
  # (scope tancredi: decrypted in the home realm on antigone). Its plaintext is
  # a beets config overlay merged in only at import time via `beet -c`, so the
  # token stays out of the world-readable Nix store that holds the rest of the
  # beets config:
  #   discogs:
  #     user_token: <token>
  # Created out of band with agenix; see the manage-music-library skill.
  "discogs-personal-access-token-turlando.age" = {
    publicKeys = with keys; [ antigone ];
    scope = with scope; [ tancredi ];
  };

  # WireGuard interface private keys, one per host, decrypted into the nixos
  # realm. creusa and antigone consume theirs via
  # networking.wireguard.interfaces.wg0.privateKeyFile; medea's is env-format
  # (WG_PRIVATE_KEY=...) for NetworkManager's ensureProfiles.environmentFiles.
  # The public halves live in registry/wireguard-devices.nix.
  "wireguard-creusa-key.age" = {
    publicKeys = with keys; [ creusa ];
    scope = with scope; [ nixos ];
  };

  "wireguard-antigone-key.age" = {
    publicKeys = with keys; [ antigone ];
    scope = with scope; [ nixos ];
  };

  "wireguard-medea-key.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ nixos ];
  };

  # SSH client keys follow the convention
  #   ssh-key_<target_host>-<target_user>_<source_host>-<source_user>
  # so each key names the grant it represents: the private half lets
  # <source_user>@<source_host> authenticate as <target_user>@<target_host>.
  # Hence publicKeys is the source host (the only place the key is
  # decrypted, since it is used there as an SSH client identity) and scope
  # is the source user's realm. The public half lives in ssh-keys.nix under
  # the same tuple and is installed into the target's authorized_keys (our
  # hosts) or registered with the service (github/gitlab/compiler).

  "ssh-key_creusa-root_medea-tancredi.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ tancredi ];
  };

  "ssh-key_antigone-root_medea-tancredi.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ tancredi ];
  };

  "ssh-key_antigone-tancredi_medea-tancredi.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ tancredi ];
  };

  "ssh-key_github-git_medea-tancredi.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ tancredi ];
  };

  "ssh-key_gitlab-git_medea-luminovo.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ luminovo ];
  };

  "ssh-key_compiler4-tancredi_medea-luminovo.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ luminovo ];
  };

  # Hetzner API token for project Personal.
  "hetzner-api-token-personal.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ infra ];
  };
}
