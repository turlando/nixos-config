{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.environment.sshPublicKeys = mkOption {
    type = types.attrsOf types.str;
    readOnly = true;
    default = import ../../../secrets/ssh-keys.nix;
    description = ''
      Catalog of public SSH keys, keyed by the name of the
      ssh-key-<name>.age secret each one is the public half of.

      This module is only the accessor: the keys themselves live in
      secrets/ssh-keys.nix. Host configurations reference an entry as
      `config.environment.sshPublicKeys.<name>` (e.g. in
      users.users.<user>.openssh.authorizedKeys.keys) so it is always
      clear which key is being authorised.
    '';
  };
}
