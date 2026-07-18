{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.environment.age = {
    keys = mkOption {
      type = types.attrsOf (types.submodule {
        options.host = mkOption {
          type = types.str;
          description = "Host machine identity (SSH host key), the nixos-realm recipient.";
        };
        options.users = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Per-user age identities living on this host, the home-realm recipients.";
        };
      });
      readOnly = true;
      default = import ../../../registry/age-keys.nix;
      description = ''
        Catalog of agenix recipients, keyed by host name: the host's
        machine identity and the per-user age identities living on it,
        all public halves.

        This module is only the accessor: the keys live in
        registry/age-keys.nix. The age profiles select their recipient as
        `config.environment.age.keys.<host>.host` (nixos realm) or
        `.users.<user>` (home realm), so it is always clear which
        identity decrypts.
      '';
    };

    scopes = mkOption {
      type = types.attrsOf types.str;
      readOnly = true;
      default = import ../../../registry/age-scopes.nix;
      description = ''
        Catalog of secret scopes: the realms a secret is filtered for by
        lib/age.nix's mkSecrets (each entry in secrets/secrets.nix lists
        the scopes it belongs to).

        This module is only the accessor: the scopes live in
        registry/age-scopes.nix. The age profiles select theirs as
        `config.environment.age.scopes.<realm>`.
      '';
    };
  };
}
