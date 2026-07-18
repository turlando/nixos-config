let
  ephemeral = ./ephemeral.nix;
  journald = ./journald.nix;
in
{
  inherit ephemeral journald;
  default.imports = [
    ephemeral
    journald
  ];
}
