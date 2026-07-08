{ lib }:

let
  eval = (lib.evalModules {
    modules = [ ../../nixos/modules/environment/ids.nix ];
  }).config;

  inherit (eval.environment) ids;

  # Number of duplicate values in a list (0 means every value is unique).
  duplicates = xs: (lib.length xs) - (lib.length (lib.unique xs));
in
{
  test_no_duplicate_uids = {
    expr = duplicates (lib.attrValues ids.uids);
    expected = 0;
  };

  test_no_duplicate_gids = {
    expr = duplicates (lib.attrValues ids.gids);
    expected = 0;
  };
}
