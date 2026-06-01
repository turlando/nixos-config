{
  system.stateVersion = "26.05";

  networking.hostName = "medea";
  networking.hostId = "e8d8a1f8";
  #networking.interfaces.eth0 =  { macAddress = "9c:bf:0d:00:be:a2"; };
  networking.interfaces.wlan0 = { macAddress = "d8:b3:2f:bd:d6:f1"; };

  hardware.framework = {
    enable = true;

    # Keep cell voltage below ~4.1 V (80% SoC) instead of the 4.2 V at 100%.
    chargeLimit = 80;

    # Gentle 0.5 C rate (~1958 mA) reduces charging heat and lithium-plating risk.
    chargeRateLimit = 0.5;

    # Only enforce the rate limit above 50 % SoC, where cell voltage is highest
    # and stress matters most. Below 50% the battery charges at full speed.
    chargingLimitSoc = 50;
  };

  i18n.extra-locale = "it_IT.UTF-8";
  time.timeZone = "Europe/Rome";
}
