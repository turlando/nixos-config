{ lib }:

let
  lib-age = import ../../lib/age.nix { inherit lib; };

  secrets = {
    "a.age" = {
      publicKeys = [ "k1" ];
      scope = [ "nixos" ];
    };

    "b.age" = {
      publicKeys = [ "k1" ];
      scope = [ "alice" ];
    };

    "c.age" = {
      publicKeys = [ "k2" ];
      scope = [ "alice" "bob" ];
    };

    "d.age" = {
      publicKeys = [ "k1" ];
      scope = [ "bob" ];
    };
  };

  dir = "/secrets";
in
{
  test_filters_by_key_and_scope = {
    expr = lib-age.mkSecrets {
      key = "k1";
      scope = "nixos";
      inherit secrets dir;
    };

    expected = {
      a = { file = "/secrets/a.age"; };
    };
  };

  test_user_scope = {
    expr = lib-age.mkSecrets {
      key = "k1";
      scope = "alice";
      inherit secrets dir;
    };

    expected = {
      b = { file = "/secrets/b.age"; };
    };
  };

  test_multi_scope_secret = {
    expr = lib-age.mkSecrets {
      key = "k2";
      scope = "alice";
      inherit secrets dir;
    };

    expected = {
      c = { file = "/secrets/c.age"; };
    };
  };

  test_user_scopes_are_isolated = {
    expr = lib-age.mkSecrets {
      key = "k1";
      scope = "bob";
      inherit secrets dir;
    };

    expected = {
      d = { file = "/secrets/d.age"; };
    };
  };

  test_no_matches = {
    expr = lib-age.mkSecrets {
      key = "nope";
      scope = "nixos";
      inherit secrets dir;
    };

    expected = { };
  };
}
