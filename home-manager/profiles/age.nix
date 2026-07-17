{ config, nixosConfiguration, lib-age,  ... }:

{
  age = {
    identityPaths = [ "${config.home.homeDirectory}/${lib-age.userKeyFile}" ];
    secrets = lib-age.mkSecrets {
      key   = lib-age.keys.${nixosConfiguration.networking.hostName}.users.${config.home.username};
      scope = lib-age.scope.${config.home.username};
    };
  };
}
