{ lib }:
{
  ephemeral = import ./ephemeral.nix { inherit lib; };
  framework = import ./framework.nix { inherit lib; };
  journald = import ./journald.nix { inherit lib; };
  persistence = import ./persistence.nix { inherit lib; };
}

