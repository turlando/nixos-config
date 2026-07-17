{ config, lib-age, ... }:

{
  environment.persistence.paths = [ lib-age.keyDir ];

  # The host identity is provisioned out of band and persisted, so nothing in
  # the config rewrites it. Enforce 0600 so a stray chmod cannot leave it
  # world-readable, which would expose every host secret to any local user.
  systemd.tmpfiles.rules = [ "z ${lib-age.identityFile} 0600 root root -" ];

  age = {
    identityPaths = [ lib-age.identityFile ];
    secrets = lib-age.mkSecrets {
      key   = lib-age.keys.${config.networking.hostName}.host;
      scope = lib-age.scope.nixos;
    };
  };
}
