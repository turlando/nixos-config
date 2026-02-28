{ config, nixosConfiguration, lib-age,  ... }:

{
  age = {
    inherit (nixosConfiguration.age) identityPaths;
    secrets = lib-age.mkSecrets {
      key   = lib-age.keys.${nixosConfiguration.networking.hostName};
      scope = lib-age.scope.${config.home.username};
    };
  };
}
