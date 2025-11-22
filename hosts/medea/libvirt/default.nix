{ pkgs, nixvirt, ... }:

{
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      { definition = nixvirt.lib.domain.writeXML (import ./domain-tersicore.nix { inherit pkgs; }); }
    ];

    networks = [
      {
        active = true;
        definition = nixvirt.lib.network.writeXML (import ./network-default.nix);
        restart = null;
      }
    ];

    pools = null;
  };
}
