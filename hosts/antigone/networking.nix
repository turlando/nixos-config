{ config, ... }:
{
  # Remote unlock of the encrypted root: the initrd brings up wan0 (DHCP)
  # and runs sshd on port 2222 so the ZFS passphrase can be entered before
  # the pool is mounted. Connect with `ssh -p 2222 root@<ip>`, then type
  # the passphrase. The host key is appended to the initrd at activation
  # (not the Nix store), so it sits unencrypted on the ESP; it is only an
  # SSH identity, not the disk key.
  boot.initrd.availableKernelModules = [ "e1000e" ];
  boot.kernelParams = [ "ip=dhcp" ];
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    port = 2222;
    authorizedKeys = [ config.environment.sshPublicKeys.antigone-root_medea-tancredi ];
    hostKeys = [ "/var/state/secrets/initrd/ssh_host_ed25519_key" ];
  };

  # Pin interface names by MAC so they stay stable across reboots and as
  # NICs are added.

  # wan0: builtin NIC (e1000e), uplink to the ZTE modem.
  systemd.network.links."10-wan0" = {
    matchConfig.MACAddress = "10:7b:44:49:e6:8a";
    linkConfig.Name = "wan0";
  };

  # lan0: PCIe NIC (r8169), the trusted apartment LAN.
  systemd.network.links."10-lan0" = {
    matchConfig.MACAddress = "c4:e9:84:04:c2:64";
    linkConfig.Name = "lan0";
  };
}
