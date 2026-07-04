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
