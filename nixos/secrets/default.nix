{ config, lib, ... }: {
  environment.persistence.paths = [ "/etc/agenix" ];

  age = {
    identityPaths = [ "/etc/agenix/key" ];

    secrets = {
      users-luminovo-password.file = ./users-luminovo-password.age;
      users-root-password.file = ./users-root-password.age;
      users-tancredi-password.file = ./users-tancredi-password.age;
    };
  };
}
