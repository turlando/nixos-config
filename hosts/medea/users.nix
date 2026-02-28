{ config, pkgs, ... }:

{
  users.users = {
    root = {
      hashedPasswordFile = config.age.secrets.users-root-password.path;
    };

    tancredi = {
      uid = 1000;
      description = "Tancredi Orlando";
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.users-tancredi-password.path;
      shell = pkgs.zsh;
      extraGroups = [
        config.users.groups.wheel.name
        config.users.groups.libvirtd.name
      ];
    };

    luminovo = {
      uid = 1001;
      description = "Luminovo GmbH";
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.users-luminovo-password.path;
      shell = pkgs.zsh;
      extraGroups = [ config.users.groups.wheel.name ];
    };
  };
}
