{ config, flake, ... }:
let
  inherit (flake.lib) net;
  inherit (config.environment.network) hosts subnets;
in
{
  # WireGuard hub. creusa has a stable public IP, so the spokes dial in here:
  # antigone (home, behind a rotating WAN) and roaming clients like medea.
  # creusa forwards between them, so a roaming client reaches antigone's LAN
  # through the tunnel without antigone needing a fixed, reachable endpoint.
  networking.wireguard.interfaces.wg0 = {
    ips = [ (net.withPrefix hosts.creusa.interfaces.wg0.address subnets.wireguard.cidr) ];
    listenPort = config.environment.wireguard.devices.creusa.listenPort;
    privateKeyFile = config.age.secrets.wireguard-creusa-key.path;

    peers = [
      # antigone: its tunnel address plus the apartment LAN behind it, so
      # traffic for 10.241.23.0/24 routes here and on to antigone. No endpoint:
      # antigone dials in and creusa learns its address from the handshake.
      {
        publicKey = config.environment.wireguard.devices.antigone.publicKey;
        allowedIPs = [
          "${hosts.antigone.interfaces.wg0.address}/32"
          subnets.lan.cidr
        ];
      }
      # antigone's initrd unlock identity: only its own address, so you can SSH
      # the initrd over the tunnel to enter the disk passphrase at boot.
      {
        publicKey = config.environment.wireguard.devices.antigone-initrd.publicKey;
        allowedIPs = [ "${hosts.antigone.interfaces.wg0-initrd.address}/32" ];
      }
      # medea: a single roaming client.
      {
        publicKey = config.environment.wireguard.devices.medea.publicKey;
        allowedIPs = [ "${hosts.medea.interfaces.wg0.address}/32" ];
      }
    ];
  };

  # Forward between peers on the tunnel (roaming client <-> antigone's LAN).
  # The nftables firewall keeps the forward chain default-deny (filterForward),
  # so only tunnel-to-tunnel traffic is allowed and conntrack accepts the
  # return path. The public link cannot forward, so creusa is no open relay.
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;
  networking.nftables.enable = true;
  networking.firewall.filterForward = true;
  networking.firewall.extraForwardRules = ''
    iifname "wg0" oifname "wg0" accept
  '';

  # Accept the tunnel handshake on the public link, and trust peers to reach
  # creusa's own services (e.g. actual-budget) over wg0.
  networking.firewall.interfaces.eth0.allowedUDPPorts = [
    config.environment.wireguard.devices.creusa.listenPort
  ];
  networking.firewall.trustedInterfaces = [ "wg0" ];
}
