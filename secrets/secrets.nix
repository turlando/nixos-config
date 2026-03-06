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

  # SSH key for user tancredi on antigone from medea.
  "ssh-key-antigone-tancredi.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ tancredi ];
  };

  # SSH key for turlando GitHub account on medea.
  "ssh-key-github.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ tancredi ];
  };

  # SSH key for Luminovo GitLab account on medea.
  "ssh-key-luminovo-gitlab.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ luminovo ];
  };

  # SSH key for Luminovo compiler machines on medea.
  "ssh-key-luminovo-compilers.age" = {
    publicKeys = with keys; [ medea ];
    scope = with scope; [ luminovo ];
  };
}
