{ config, lib-age, ... }:

{
  environment.persistence.paths = [ "/etc/agenix" ];

  age = {
    identityPaths = [ "/etc/agenix/key" ];   
    secrets = lib-age.mkSecrets {
      key   = lib-age.keys.${config.networking.hostName};
      scope = lib-age.scope.nixos;
    };
  };
}
