{ nixvirt }:
{ pkgs, ... }:
{
  imports = [
    nixvirt.nixosModules.default
  ];

  config = {
    virtualisation.libvirt = {
      enable = true;
      swtpm.enable = true;
    };

    virtualisation.libvirtd = {
      qemu = {
        package = pkgs.qemu_kvm;
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };

    virtualisation.spiceUSBRedirection.enable = true;
  };
}
