{ lib }:
{
  ephemeral = import ./ephemeral.nix { inherit lib; };
  families = import ./families.nix { inherit lib; };
  framework = import ./framework.nix { inherit lib; };
  index = import ./index.nix { inherit lib; };
  journald = import ./journald.nix { inherit lib; };
  persistence = import ./persistence.nix { inherit lib; };
  unix-ids = import ./unix-ids.nix { inherit lib; };
}
