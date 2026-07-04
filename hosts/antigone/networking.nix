{ config, pkgs, ... }:
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

  # Networking backend: systemd-networkd. wan0 stays a DHCP client of the
  # ZTE so the uplink is unchanged; lan0 is the static LAN gateway.
  # wait-online is disabled so a down WAN or idle LAN never blocks or
  # degrades boot; services self-heal as links come up.
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.wait-online.enable = false;
  systemd.network.networks = {
    "10-wan0" = {
      matchConfig.Name = "wan0";
      networkConfig.DHCP = "ipv4";
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

  # Firewall: trust lan0 (the apartment LAN); wan0 stays default-deny
  # inbound, passing only conntrack-established return traffic.
  networking.firewall.trustedInterfaces = [ "lan0" ];

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

  # DNS: unbound is the caching resolver for antigone and the LAN. It
  # forwards to Quad9 over DoT and answers authoritatively for the perosi
  # site zone (and its reverse), so ap0.perosi.rhyzomatic.net resolves
  # locally. resolveLocalQueries points antigone's own queries here too.
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
        ];
        tls-cert-bundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        local-zone = [
          ''"perosi.rhyzomatic.net." static''
          ''"23.241.10.in-addr.arpa." static''
        ];
        local-data = [
          ''"antigone.perosi.rhyzomatic.net. IN A 10.241.23.1"''
          ''"ap0.perosi.rhyzomatic.net. IN A 10.241.23.11"''
        ];
        local-data-ptr = [
          ''"10.241.23.1 antigone.perosi.rhyzomatic.net"''
          ''"10.241.23.11 ap0.perosi.rhyzomatic.net"''
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
