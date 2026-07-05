{ config, pkgs, ... }:

let
  keyDir = "/var/lib/initrd-ssh";
  hostKey = "${keyDir}/ssh_host_ed25519_key";
in {
  environment.persistence.paths = [ keyDir ];

  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    port = 2222;
    hostKeys = [ hostKey ];
  };

  # NixOS does not generate initrd host keys, so generate ours on activation
  # if absent, before the bootloader bakes it into the initrd. It is a
  # separate identity from the system host key: it sits unencrypted on the
  # ESP, where the system key must never be. Only an SSH identity, not the
  # disk key.
  system.activationScripts.initrdSshHostKey.text = ''
    if [ ! -f ${hostKey} ]; then
      mkdir -p ${keyDir}
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" \
        -C "${config.networking.hostName}-initrd" -f ${hostKey}
    fi
  '';
}
