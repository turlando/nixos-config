{ flake, pkgs, ... }:
{
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      {
        definition = flake.inputs.nixvirt.lib.domain.writeXML
          (import ./domain-tersicore.nix {
            ovmf = pkgs.OVMFFull;
          });
      }
    ];

    networks = [
      {
        active = true;
        definition = flake.inputs.nixvirt.lib.network.writeXML (import ./network-default.nix);
        restart = null;
      }
    ];

    pools = null;
  };
}
