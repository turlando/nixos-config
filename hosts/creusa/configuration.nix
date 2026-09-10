{ config, ... }:
{
  system.stateVersion = "26.05";

  networking.hostName = "creusa";
  networking.hostId = "4bf5d147";
  networking.interfaces.eth0 =  { macAddress = "92:00:07:55:51:fc"; };

  # Fixed machine-id. The root dataset is ephemeral and /etc/machine-id is not
  # persisted; systemd derived the id from the VM DMI UUID so far, which
  # pinning keeps independent of the hypervisor.
  environment.etc."machine-id".text = "540fa9247b9f4a399c03728fbcd2886e";

  environment.persistence.enable = true;
  services.ephemeral.enable = true;
  services.ephemeral.datasets."creusa/nixos/ROOT".enable = true;

  users.users.root = {
    hashedPasswordFile = config.age.secrets.user-password-creusa-root.path;
    openssh.authorizedKeys.keys = [ config.environment.ssh.publicKeys.creusa-root_medea-tancredi ];
  };
}
