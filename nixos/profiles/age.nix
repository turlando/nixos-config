{ config, flake, ... }:

{
  environment.persistence.paths = [ flake.lib.age.keyDir ];

  # The host identity is provisioned out of band and persisted, so nothing in
  # the config rewrites it. Enforce 0600 so a stray chmod cannot leave it
  # world-readable, which would expose every host secret to any local user.
  systemd.tmpfiles.rules = [ "z ${flake.lib.age.identityFile} 0600 root root -" ];

  age = {
    identityPaths = [ flake.lib.age.identityFile ];
    secrets = flake.lib.age.mkSecrets {
      key   = flake.lib.age.keys.${config.networking.hostName}.host;
      scope = flake.lib.age.scope.nixos;
    };
  };
}
