{ lib }:

let
  network = import ../../registry/network.nix;

  # The registry is a graph expressed through attribute keys: record answers
  # reference views and host interfaces, interfaces reference subnets. These
  # tests are the referential-integrity checks; each returns the offending
  # paths, so a dangling reference names its culprit.

  # Record answers naming a view not declared in dns.views.
  undeclaredViews = lib.concatLists (lib.mapAttrsToList
    (slug: record:
      map (view: "records.${slug}.views.${view}")
        (lib.filter (view: !(lib.hasAttr view network.dns.views))
          (lib.attrNames (record.views or {}))))
    network.dns.records);

  # Interface answers referencing a host interface missing from hosts.
  danglingTargets = lib.concatLists (lib.mapAttrsToList
    (slug: record: lib.concatLists (lib.mapAttrsToList
      (view: answer:
        lib.optional
          (answer ? interface && !(lib.hasAttrByPath
            [ answer.interface.host "interfaces" answer.interface.interface ]
            network.hosts))
          "records.${slug}.views.${view}")
      (record.views or {})))
    network.dns.records);

  # Interfaces referencing a subnet missing from subnets.
  danglingSubnets = lib.concatLists (lib.mapAttrsToList
    (host: cfg: lib.concatLists (lib.mapAttrsToList
      (name: interface:
        lib.optional
          (interface ? subnet && !(lib.hasAttr interface.subnet network.subnets))
          "hosts.${host}.interfaces.${name}")
      cfg.interfaces))
    network.hosts);
in
{
  test_record_views_are_declared = {
    expr = undeclaredViews;
    expected = [];
  };

  test_record_targets_resolve = {
    expr = danglingTargets;
    expected = [];
  };

  test_interface_subnets_exist = {
    expr = danglingSubnets;
    expected = [];
  };
}
