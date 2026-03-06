{ config, pkgs, ... }:

{
  users.users = {
    root = {
      hashedPasswordFile = config.age.secrets.user-password-root.path;
    };

    tancredi = {
      uid = 1000;
      description = "Tancredi Orlando";
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.user-password-tancredi.path;
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
      hashedPasswordFile = config.age.secrets.user-password-medea-luminovo.path;
      shell = pkgs.zsh;
      extraGroups = [ config.users.groups.wheel.name ];
    };
  };
}
