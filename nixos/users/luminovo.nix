{ config, pkgs, ... }:

{
  users.users.luminovo = {
    uid = 1001;
    description = "Luminovo GmbH";
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.users-luminovo-password.path;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };
}
