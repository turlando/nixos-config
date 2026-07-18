{ lib }:

let
  net = import ../../lib/net.nix { inherit lib; };
in
{
  test_ipv4_address_accepts_valid = {
    expr = map net.types.ipv4Address.check [
      "10.241.23.1"
      "0.0.0.0"
      "255.255.255.255"
    ];
    expected = [ true true true ];
  };

  test_ipv4_address_rejects_invalid = {
    expr = map net.types.ipv4Address.check [
      "10.241.23"
      "10.241.23.256"
      "10.241.023.1"
      "10.241.23.1/24"
      "example.com"
    ];
    expected = [ false false false false false ];
  };

  test_ipv4_cidr_accepts_valid = {
    expr = map net.types.ipv4Cidr.check [
      "10.241.0.0/16"
      "10.241.23.0/24"
      "10.241.46.2/32"
      "0.0.0.0/0"
    ];
    expected = [ true true true true ];
  };

  test_ipv4_cidr_rejects_invalid = {
    expr = map net.types.ipv4Cidr.check [
      "10.241.23.0"
      "10.241.23.0/33"
      "10.241.23.0/240"
    ];
    expected = [ false false false ];
  };

  test_mac_address_accepts_valid = {
    expr = net.types.macAddress.check "c4:e9:84:04:c2:64";
    expected = true;
  };

  test_mac_address_rejects_invalid = {
    expr = map net.types.macAddress.check [
      "C4:E9:84:04:C2:64"
      "c4:e9:84:04:c2"
      "c4-e9-84-04-c2-64"
    ];
    expected = [ false false false ];
  };

  test_prefix_length = {
    expr = net.prefixLength "10.241.23.0/24";
    expected = "24";
  };

  test_with_prefix = {
    expr = net.withPrefix "10.241.23.1" "10.241.23.0/24";
    expected = "10.241.23.1/24";
  };

  test_reverse_zone_of_a_24 = {
    expr = net.reverseZone "10.241.23.0/24";
    expected = "23.241.10.in-addr.arpa";
  };

  test_reverse_zone_of_a_16 = {
    expr = net.reverseZone "10.241.0.0/16";
    expected = "241.10.in-addr.arpa";
  };

  test_reverse_zone_of_an_8 = {
    expr = net.reverseZone "10.0.0.0/8";
    expected = "10.in-addr.arpa";
  };

  test_answer_address_follows_interface_reference = {
    expr = net.answerAddress
      { antigone.interfaces.lan0.address = "10.241.23.1"; }
      { interface = { host = "antigone"; interface = "lan0"; }; };
    expected = "10.241.23.1";
  };

  test_answer_address_returns_literal_address = {
    expr = net.answerAddress { } { address = "192.0.2.7"; };
    expected = "192.0.2.7";
  };
}
