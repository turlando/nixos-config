{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.environment.ssh.publicKeys = mkOption {
    type = types.attrsOf types.str;
    readOnly = true;
    default = import ../../../registry/ssh-public-keys.nix;
    description = ''
      Catalog of public SSH keys, keyed by the name of the
      ssh-key-<name>.age secret each one is the public half of.

      This module is only the accessor: the keys themselves live in
      registry/ssh-public-keys.nix. Host configurations reference an entry as
      `config.environment.ssh.publicKeys.<name>` (e.g. in
      users.users.<user>.openssh.authorizedKeys.keys) so it is always
      clear which key is being authorised.
    '';
  };
}
