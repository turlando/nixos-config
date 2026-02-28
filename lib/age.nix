{ lib }:

let
  # Default secrets directory (relative to this file)
  defaultSecretsPath = ../secrets;

  # Default secrets and keys
  allSecrets = import (defaultSecretsPath + "/secrets.nix");
  keys       = import (defaultSecretsPath + "/keys.nix");
  scope      = import (defaultSecretsPath + "/scope.nix");

  # mkSecrets { key, scope, secrets?, dir? }
  #
  # Build a filtered age.secrets attrset from an agenix-style
  # secrets.nix mapping.
  #
  # The function:
  #   - Filters secrets whose `publicKeys` contain `key`
  #   - Filters secrets whose `scope` list contains `scope`
  #   - Strips the `.age` suffix to derive the secret name
  #   - Constructs the file path using `dir`
  #
  # Produces:
  #
  #   {
  #     secret-name.file = /path/to/secret-name.age;
  #   }
  #
  # Parameters:
  #   key    : public key used for filtering
  #   scope  : one of the values from secrets/scope.nix
  #   secrets: (optional) secrets attrset (defaults to ../secrets/secrets.nix)
  #   dir    : (optional) directory containing .age files (defaults to ../secrets)
  #
  mkSecrets =
    { key
    , scope
    , secrets ? allSecrets
    , dir     ? defaultSecretsPath
    }:
    let
      hasKey = attrs: builtins.elem key (attrs.publicKeys or []);
      hasScope = attrs: builtins.elem scope (attrs.scope or []);

      filtered =
        lib.filterAttrs
          (_: attrs: hasKey attrs && hasScope attrs)
          secrets;

      mkEntry = fileName: _:
        let secretName = lib.removeSuffix ".age" fileName;
        in { ${secretName} = { file = dir + "/${fileName}"; }; };
    in
      builtins.foldl'
        (acc: entry: acc // entry)
        {}
        (builtins.attrValues (builtins.mapAttrs mkEntry filtered));

in
{
  inherit
    keys
    scope
    mkSecrets;
}
