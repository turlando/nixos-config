{ config, lib-age, ... }:

{
  environment.persistence.paths = [ lib-age.keyDir ];

  age = {
    identityPaths = [ lib-age.identityFile ];
    secrets = lib-age.mkSecrets {
      key   = lib-age.keys.${config.networking.hostName};
      scope = lib-age.scope.nixos;
    };
  };
}
