{ config, pkgs, lib, ... }:

let
  inherit (lib.attrsets) mergeAttrsets;
  inherit (lib.files) getSshKey readPassword;

  inherit (config.users) groups;
in
{
  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults lecture="never"
    '';
  };

  users = {
    mutableUsers = false;

    users = {
      root = {
        hashedPassword = readPassword "tancredi";
        openssh.authorizedKeys.keyFiles = [ (getSshKey "tancredi") ];
      };

      tancredi = {
        isNormalUser = true;
        hashedPassword = readPassword "tancredi";
        shell = pkgs.zsh;
        extraGroups = [
          groups.wheel.name
          groups.storage.name
        ];
        openssh.authorizedKeys.keyFiles = [ (getSshKey "tancredi") ];
      };
    };
  };
}
