lib:

let
  inherit (builtins) head tail;
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.lists) foldl;
in
{
  # type: [AttrSet] -> AttrSet
  mergeAttrsets = xs: foldl recursiveUpdate (head xs) (tail xs);
}
