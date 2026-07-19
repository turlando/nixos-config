{ lib }:

let
  network = import ../../registry/network.nix;
  net = import ../../lib/net.nix { inherit lib; };

  # The registry is a graph expressed through attribute keys: record answers
  # reference views and host interfaces, interfaces reference subnets,
  # subnets declare their block. These tests are the referential-integrity
  # and allocation checks; each returns the offending paths, so a violation
  # names its culprit.

  # Unordered pairs of attribute names, for pairwise checks.
  pairsOf = attrs:
    let names = lib.attrNames attrs;
    in lib.concatLists (lib.imap0
      (i: a: map (b: { inherit a b; }) (lib.drop (i + 1) names))
      names);

  overlapping = attrs: map (pair: "${pair.a} & ${pair.b}")
    (lib.filter
      (pair: net.cidrsOverlap attrs.${pair.a}.cidr attrs.${pair.b}.cidr)
      (pairsOf attrs));

  # Values appearing more than once in a list.
  duplicatesIn = values:
    lib.attrNames (lib.filterAttrs (_: hits: lib.length hits > 1)
      (lib.groupBy (value: value) values));

  forEachInterface = f: lib.concatLists (lib.mapAttrsToList
    (host: cfg: lib.concatLists (lib.mapAttrsToList
      (name: interface: f "hosts.${host}.interfaces.${name}" interface)
      cfg.interfaces))
    network.hosts);

  forEachAnswer = f: lib.concatLists (lib.mapAttrsToList
    (slug: record: lib.concatLists (lib.mapAttrsToList
      (view: answer: f "records.${slug}.views.${view}" record view answer)
      (record.views or {})))
    network.dns.records);

  # Record answers naming a view not declared in dns.views.
  undeclaredViews = forEachAnswer (path: _: view: _:
    lib.optional (!(lib.hasAttr view network.dns.views)) path);

  # Interface answers referencing a host interface missing from hosts.
  danglingTargets = forEachAnswer (path: _: _: answer:
    lib.optional
      (answer ? interface && !(lib.hasAttrByPath
        [ answer.interface.host "interfaces" answer.interface.interface ]
        network.hosts))
      path);

  # Interfaces referencing a subnet missing from subnets.
  danglingSubnets = forEachInterface (path: interface:
    lib.optional
      (interface ? subnet && !(lib.hasAttr interface.subnet network.subnets))
      path);

  # Interface addresses lying outside their declared subnet.
  addressesOutsideSubnet = forEachInterface (path: interface:
    lib.optional
      (interface ? subnet
        && (interface.address or null) != null
        && lib.hasAttr interface.subnet network.subnets
        && !net.cidrContains
          network.subnets.${interface.subnet}.cidr
          "${interface.address}/32")
      path);

  # The same address claimed by more than one interface.
  duplicateAddresses = duplicatesIn (forEachInterface (_: interface:
    lib.optional ((interface.address or null) != null) interface.address));

  # Subnets declaring a block whose range does not contain them.
  misdeclaredSubnets = lib.concatLists (lib.mapAttrsToList
    (name: subnet:
      lib.optional
        (subnet.block != null
          && !net.cidrContains network.blocks.${subnet.block}.cidr subnet.cidr)
        "subnets.${name} declares blocks.${subnet.block} but lies outside it")
    network.subnets);

  # Host-local subnets (block = null) overlapping some block's plan.
  localSubnetsInsideBlocks = lib.concatLists (lib.mapAttrsToList
    (name: subnet: lib.concatLists (lib.mapAttrsToList
      (blockName: block:
        lib.optional
          (subnet.block == null && net.cidrsOverlap block.cidr subnet.cidr)
          "subnets.${name} declares no block but overlaps blocks.${blockName}")
      network.blocks))
    network.subnets);

  # ptr records whose answers carry no address to reverse-map.
  ptrsWithoutAddresses = forEachAnswer (path: record: _: answer:
    lib.optional
      ((record.ptr or false) && !(answer ? interface || answer ? address))
      path);

  # More than one ptr record for the same address within one view.
  duplicatePtrAddresses = lib.concatLists (map
    (view: map (address: "view ${view}: ${address}")
      (duplicatesIn (lib.concatLists (lib.mapAttrsToList
        (_: record:
          let answer = (record.views or {}).${view} or null;
          in lib.optional
            ((record.ptr or false) && answer != null
              && (answer ? interface || answer ? address))
            (net.answerAddress network.hosts answer))
        network.dns.records))))
    (lib.attrNames network.dns.views));

  # The same fully qualified name under two record slugs.
  duplicateRecordNames = duplicatesIn
    (lib.mapAttrsToList (_: record: record.name) network.dns.records);
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

  test_interface_addresses_lie_inside_their_subnet = {
    expr = addressesOutsideSubnet;
    expected = [];
  };

  test_addresses_are_unique = {
    expr = duplicateAddresses;
    expected = [];
  };

  test_subnets_do_not_overlap = {
    expr = overlapping network.subnets;
    expected = [];
  };

  test_blocks_do_not_overlap = {
    expr = overlapping network.blocks;
    expected = [];
  };

  test_declared_subnets_lie_inside_their_block = {
    expr = misdeclaredSubnets;
    expected = [];
  };

  test_local_subnets_lie_outside_every_block = {
    expr = localSubnetsInsideBlocks;
    expected = [];
  };

  test_ptr_answers_bear_addresses = {
    expr = ptrsWithoutAddresses;
    expected = [];
  };

  test_ptr_addresses_are_unique_per_view = {
    expr = duplicatePtrAddresses;
    expected = [];
  };

  test_record_names_are_unique = {
    expr = duplicateRecordNames;
    expected = [];
  };
}
