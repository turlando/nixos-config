{ config, pkgs, ... }:

{
  users.users.tancredi = {
    uid = 1000;
    description = "Tancredi Orlando";
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.users-tancredi-password.path;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };
}
