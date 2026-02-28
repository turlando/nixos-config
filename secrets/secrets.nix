let
  keys = import ./keys.nix;
  scope = import ./scope.nix;
in
{
  # Hashed login password for root UNIX user.
  "users-root-password.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ nixos ];
  };

  # Hashed login password for tancredi UNIX user.
  "users-tancredi-password.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ nixos ];
  };

  # Login password for luminovo UNIX user.
  "users-luminovo-password.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ nixos ];
  };

  # SSH key for tancredi@antigone
  "ssh-key-antigone-tancredi.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ tancredi ];
  };

  # SSH key for turlando GitHub account
  "ssh-key-github.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ tancredi ];
  };

  # SSH key for Luminovo GitLab account
  "ssh-key-luminovo-gitlab.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ luminovo ];
  };

  # SSH key for Luminovo compiler machines
  "ssh-key-luminovo-compilers.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ luminovo ];
  };
}
