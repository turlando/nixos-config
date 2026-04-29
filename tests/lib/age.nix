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
  testFiltersByKeyAndScope = {
    expr = lib-age.mkSecrets {
      key = "k1";
      scope = "nixos";
      inherit secrets dir;
    };

    expected = {
      a = { file = "/secrets/a.age"; };
    };
  };

  testUserScope = {
    expr = lib-age.mkSecrets {
      key = "k1";
      scope = "alice";
      inherit secrets dir;
    };

    expected = {
      b = { file = "/secrets/b.age"; };
    };
  };

  testMultiScopeSecret = {
    expr = lib-age.mkSecrets {
      key = "k2";
      scope = "alice";
      inherit secrets dir;
    };

    expected = {
      c = { file = "/secrets/c.age"; };
    };
  };

  testUserScopesAreIsolated = {
    expr = lib-age.mkSecrets {
      key = "k1";
      scope = "bob";
      inherit secrets dir;
    };

    expected = {
      d = { file = "/secrets/d.age"; };
    };
  };

  testNoMatches = {
    expr = lib-age.mkSecrets {
      key = "nope";
      scope = "nixos";
      inherit secrets dir;
    };

    expected = { };
  };
}
