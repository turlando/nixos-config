{ config, flake, ... }:

{
  age = {
    identityPaths = [ "${config.home.homeDirectory}/${flake.lib.age.userKeyFile}" ];
    secrets = flake.lib.age.mkSecrets {
      key   = flake.lib.age.keys.${config.environment.hostName}.users.${config.home.username};
      scope = flake.lib.age.scope.${config.home.username};
    };
  };
}
