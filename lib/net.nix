{ lib }:

let
  # One dotted-quad octet, 0-255, no leading zeros.
  octet = "(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])";
  ipv4 = "${octet}(\\.${octet}){3}";
  prefix = "([0-9]|[12][0-9]|3[0-2])";

  # Prefix length of a CIDR, as the string after the slash.
  prefixLength = cidr: lib.elemAt (lib.splitString "/" cidr) 1;
in
{
  types = {
    ipv4Address = lib.types.strMatching ipv4 // {
      name = "ipv4Address";
      description = "IPv4 address";
    };

    ipv4Cidr = lib.types.strMatching "${ipv4}/${prefix}" // {
      name = "ipv4Cidr";
      description = "IPv4 subnet in CIDR notation";
    };

    macAddress = lib.types.strMatching "([0-9a-f]{2}:){5}[0-9a-f]{2}" // {
      name = "macAddress";
      description = "MAC address, lowercase and colon-separated";
    };
  };

  inherit prefixLength;

  # Interface address in address/prefix notation, with the prefix taken from
  # the CIDR of the subnet the address sits in.
  withPrefix = address: cidr: "${address}/${prefixLength cidr}";

  # in-addr.arpa reverse zone of an IPv4 CIDR, defined for octet-aligned
  # prefix lengths, e.g. "10.241.23.0/24" -> "23.241.10.in-addr.arpa".
  reverseZone = cidr:
    let
      address = lib.elemAt (lib.splitString "/" cidr) 0;
      prefix = lib.toInt (prefixLength cidr);
      networkOctets = lib.take (prefix / 8) (lib.splitString "." address);
    in
      if prefix == 0 || lib.mod prefix 8 != 0
      then throw "reverseZone: prefix of ${cidr} is not octet-aligned"
      else lib.concatStringsSep "." (lib.reverseList networkOctets) + ".in-addr.arpa";

  # IPv4 answering an address-bearing DNS record answer (see the
  # environment.network accessor): the literal address, or the referenced
  # interface's address followed through the given hosts catalog.
  answerAddress = hosts: answer:
    if answer ? interface then
      hosts.${answer.interface.host}.interfaces.${answer.interface.interface}.address
    else
      answer.address or (throw
        "answerAddress: not an address-bearing answer, got: ${lib.concatStringsSep ", " (lib.attrNames answer)}");
}
