{ config, flake, ... }:

{
  age = {
    identityPaths = [ "${config.home.homeDirectory}/${flake.lib.age.userKeyFile}" ];
    secrets = flake.lib.age.mkSecrets {
      key   = config.environment.age.keys.${config.environment.hostName}.users.${config.home.username};
      scope = config.environment.age.scopes.${config.home.username};
    };
  };
}
