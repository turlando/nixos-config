{ pkgs }:

let
  lib-age = import ../lib/age.nix { inherit (pkgs) lib; };
  age-tests = import ./age.nix { inherit lib-age; };

  check = { tests }:
    let
      formatValue = val:
        if (builtins.isList val || builtins.isAttrs val)
        then builtins.toJSON val
        else builtins.toString val;
      resultToString = { name, expected, result }: ''
        ${name} failed: expected ${formatValue expected}, but got ${formatValue result}
      '';
      results = pkgs.lib.runTests tests;
    in
      if results != [ ] then
        builtins.throw (builtins.concatStringsSep "\n" (map resultToString results))
      else
        pkgs.runCommand "nix-flake-tests-success" {} "echo > $out";
in
{
  run-all = check {
    tests = age-tests;
  };
}
