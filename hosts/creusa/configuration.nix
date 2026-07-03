{ config, ... }:
{
  system.stateVersion = "26.05";

  networking.hostName = "creusa";
  networking.hostId = "4bf5d147";
  networking.interfaces.eth0 =  { macAddress = "92:00:07:55:51:fc"; };

  environment.persistence.enable = true;
  services.ephemeral.enable = true;
  services.ephemeral.datasets."creusa/nixos/ROOT".enable = true;

  services.journald.settings = {
    SystemMaxUse = "256M";
    SystemMaxFileSize = "32M";
    MaxRetentionSec = "1month";
  };

  users.users.root = {
    hashedPasswordFile = config.age.secrets.user-password-creusa-root.path;
    openssh.authorizedKeys.keys = [ config.environment.sshPublicKeys.creusa-root ];
  };
}
