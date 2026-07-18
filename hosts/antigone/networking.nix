{ config, pkgs, ... }:
let
  # Where boot.initrd.secrets bakes the initrd WG key and networkd reads it,
  # named once so the two references cannot drift apart.
  initrdWgKey = "/etc/wireguard-initrd.key";
in
{
  # Remote unlock: the initrd-openssh-server profile runs sshd (:2222) with a
  # persistent host key. lan0 unlocks from the LAN; wan0 plus a wg0 tunnel
  # dialing the creusa hub unlock over the VPN (ssh -p 2222 root@10.241.46.3),
  # reachable before the pool mounts. lan0 unlock is unaffected and stays the
  # fallback. The tunnel key is a separate unlock-only agenix secret, baked
  # into the initrd from /run/agenix at switch time; like the initrd host key
  # it lives unencrypted on the ESP, so creusa scopes its peer to its own
  # address.
  boot.initrd.availableKernelModules = [
    "e1000e"
    "r8169"
  ];
  boot.initrd.kernelModules = [ "wireguard" ];
  # In the initrd, networkd runs as the unprivileged systemd-network user and
  # must read this key to build wg0. The initrd-secrets cpio forces root:root
  # ownership, so a group grant cannot reach it: the key has to be
  # world-readable. That adds no exposure, as it is already baked unencrypted
  # onto the ESP.
  age.secrets.wireguard-antigone-initrd-key.mode = "0444";
  boot.initrd.secrets.${initrdWgKey} = config.age.secrets.wireguard-antigone-initrd-key.path;
  boot.initrd.systemd.network = {
    enable = true;
    netdevs."10-wg0" = {
      netdevConfig = {
        Name = "wg0";
        Kind = "wireguard";
      };
      wireguardConfig.PrivateKeyFile = initrdWgKey;
      wireguardPeers = [
        {
          PublicKey = config.environment.wireguard.devices.creusa.publicKey;
          Endpoint = config.environment.wireguard.devices.creusa.endpoint;
          AllowedIPs = [ "10.241.46.0/24" ];
          PersistentKeepalive = 25;
        }
      ];
    };
    networks = {
      "10-lan0" = {
        matchConfig.MACAddress = "c4:e9:84:04:c2:64";
        address = [ "10.241.23.1/24" ];
      };
      "10-wan0" = {
        matchConfig.MACAddress = "10:7b:44:49:e6:8a";
        address = [ "10.241.254.2/24" ];
        gateway = [ "10.241.254.1" ];
      };
      "10-wg0" = {
        matchConfig.Name = "wg0";
        address = [ "10.241.46.3/24" ];
      };
    };
  };
  boot.initrd.network.ssh.authorizedKeys = [ config.environment.ssh.publicKeys.antigone-root_medea-tancredi ];

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

  # Networking backend: systemd-networkd. wan0 is antigone's static uplink
  # to the ZTE on the transit segment; lan0 is the static LAN gateway.
  # wait-online is disabled so a down WAN or idle LAN never blocks or
  # degrades boot; services self-heal as links come up.
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.wait-online.enable = false;
  systemd.network.networks = {
    "10-wan0" = {
      matchConfig.Name = "wan0";
      address = [ "10.241.254.2/24" ];
      gateway = [ "10.241.254.1" ];
    };
    "10-lan0" = {
      matchConfig.Name = "lan0";
      address = [ "10.241.23.1/24" ];
    };
  };

  # NAT: masquerade lan0 traffic out wan0 so LAN clients reach the internet.
  networking.nat = {
    enable = true;
    externalInterface = "wan0";
    internalInterfaces = [ "lan0" ];
  };

  # Firewall: trust lan0 (the apartment LAN) and wg0 (the VPN) so both reach
  # antigone's services; wan0 stays default-deny inbound, passing only
  # conntrack-established return traffic.
  networking.firewall.trustedInterfaces = [ "lan0" "wg0" ];

  # SSH is management: reachable over the trusted interfaces (lan0 and the
  # wg0 VPN), never on wan0, the internet edge under DMZ.
  services.openssh.openFirewall = false;

  # WireGuard spoke. antigone dials out to the creusa hub (stable public IP)
  # and holds the tunnel open with keepalive, so it stays reachable across the
  # rotating WAN with no dynamic DNS. allowedIPs covers the WG transit, so
  # replies to roaming clients route back through creusa. antigone initiates,
  # so no inbound port is opened on wan0; creusa's replies return established.
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.241.46.2/24" ];
    privateKeyFile = config.age.secrets.wireguard-antigone-key.path;

    peers = [
      {
        publicKey = config.environment.wireguard.devices.creusa.publicKey;
        endpoint = config.environment.wireguard.devices.creusa.endpoint;
        allowedIPs = [ "10.241.46.0/24" ];
        persistentKeepalive = 25;
      }
    ];
  };

  # DHCP: kea serves the LAN on lan0 from the 10.241.23.101-200 pool,
  # handing out antigone (.1) as gateway and resolver.
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config.interfaces = [ "lan0" ];
      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp4.leases";
      };
      valid-lifetime = 86400;
      subnet4 = [
        {
          id = 1;
          subnet = "10.241.23.0/24";
          pools = [ { pool = "10.241.23.101 - 10.241.23.200"; } ];
          option-data = [
            { name = "routers";             data = "10.241.23.1"; }
            { name = "domain-name-servers"; data = "10.241.23.1"; }
          ];
        }
      ];
    };
  };

  # antigone resolves through unbound, not systemd-resolved (which would
  # otherwise use the wan0 link's DNS, i.e. the modem). With resolved off,
  # resolveLocalQueries points antigone's /etc/resolv.conf straight at
  # unbound.
  services.resolved.enable = false;

  # DNS: unbound is the caching resolver for antigone, the LAN, and roaming
  # WireGuard clients. It forwards to Quad9 over DoT and answers
  # authoritatively for rhyzomatic.net
  # and the LAN reverse zones. Managed hosts and their services sit directly
  # under the zone; site devices (ap0, modem) live under the perosi subzone.
  # resolveLocalQueries points antigone's own queries here too.
  services.unbound = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      server = {
        interface = [
          "127.0.0.1"
          "10.241.23.1"
        ];
        access-control = [
          "127.0.0.0/8 allow"
          "10.241.23.0/24 allow"
          "10.241.46.0/24 allow"
        ];
        tls-cert-bundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        local-zone = [
          ''"rhyzomatic.net." static''
          ''"23.241.10.in-addr.arpa." static''
          ''"254.241.10.in-addr.arpa." static''
        ];
        local-data = [
          ''"antigone.rhyzomatic.net. IN A 10.241.23.1"''
          ''"slskd.antigone.rhyzomatic.net. IN A 10.241.23.1"''
          ''"syncthing.antigone.rhyzomatic.net. IN A 10.241.23.1"''
          ''"ap0.perosi.rhyzomatic.net. IN A 10.241.23.11"''
          ''"modem.perosi.rhyzomatic.net. IN A 10.241.254.1"''
        ];
        local-data-ptr = [
          ''"10.241.23.1 antigone.rhyzomatic.net"''
          ''"10.241.23.11 ap0.perosi.rhyzomatic.net"''
          ''"10.241.254.1 modem.perosi.rhyzomatic.net"''
        ];
      };
      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = true;
          forward-addr = [
            "9.9.9.9@853#dns.quad9.net"
            "149.112.112.112@853#dns.quad9.net"
          ];
        }
      ];
    };
  };
}
