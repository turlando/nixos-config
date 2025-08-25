{
  system.stateVersion = "25.05";

  networking.hostName = "medea";
  networking.hostId = "e8d8a1f8";
  #networking.interfaces.eth0 =  { macAddress = "9c:bf:0d:00:be:a2"; };
  networking.interfaces.wlan0 = { macAddress = "d8:b3:2f:bd:d6:f1"; };

  services.ephemeral.enable = false;
  services.ephemeral.datasets."medea/nixos/ROOT".enable = true;

  i18n.extra-locale = "it_IT.UTF-8";
  time.timeZone = "Europe/Rome";
}
