{ config, lib, ... }: {
  environment.persistence.paths = [ "/etc/agenix" ];

  age = {
    identityPaths = [ "/etc/agenix/key" ];

    secrets = {
      users-root-password.file = ./users-root-password.age;
      users-tancredi-password.file = ./users-tancredi-password.age;
    };
  };
}
