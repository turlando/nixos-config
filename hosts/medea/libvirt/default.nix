{ nixvirt }:
{ pkgs, ... }:

# At this point nixvirt modules should already been imported.

{
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      {
        definition = nixvirt.lib.domain.writeXML
          (import ./domain-tersicore.nix {
            ovmf = pkgs.OVMFFull;
          });
      }
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
