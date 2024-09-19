{ ... }:

{
  networking.hostName = "antigone";
  networking.hostId = "4d86c32a"; # Required by ZFS

  networking.interfaces.eth0 = {
    macAddress = "f4:6d:04:7b:d3:0e";
    useDHCP = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
