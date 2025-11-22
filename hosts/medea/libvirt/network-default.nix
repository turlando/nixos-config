{
  name = "default";
  uuid = "37f03126-f06f-4bd2-a032-629f52df8871";

  forward = {
    mode = "nat";
  };

  bridge = {
    name = "virbr0";
    stp = true;
    delay = 0;
  };

  mac = {
    address = "52:54:00:65:ab:fe";
  };

  ip = {
    address = "192.168.122.1";
    netmask = "255.255.255.0";
    dhcp = {
      range = {
        start = "192.168.122.2";
        end = "192.168.122.254";
      };
    };
  };
}
