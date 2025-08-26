{ config, lib, ... }: {
  age = {
    identityPaths = [ "/etc/agenix/key" ];

    secrets = {
      ssh-key-github.file = ./ssh-key-github.age;
      ssh-key-gitlab-luminovo.file = ./ssh-key-gitlab-luminovo.age;
      ssh-key-tancredi.file = ./ssh-key-tancredi.age;
    };
  };
}
