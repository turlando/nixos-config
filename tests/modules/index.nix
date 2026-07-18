{ lib }:

let
  nixosModules = import ../../nixos/modules;
  homeModules = import ../../home-manager/modules;

  nixosRoot = ../../nixos/modules;
  homeRoot = ../../home-manager/modules;

  sorted = lib.sort lib.lessThan;

  categoriesOf = registry: removeAttrs registry [ "default" ];
  leavesOf = category: builtins.attrValues (removeAttrs category [ "default" ]);

  # Leaf module paths listed in each category's default, keyed by category.
  importedByCategory = registry:
    builtins.mapAttrs
      (_: category: sorted (map toString category.default.imports))
      (categoriesOf registry);

  # Leaf module paths registered in each category, keyed by category.
  registeredByCategory = registry:
    builtins.mapAttrs
      (_: category: sorted (map toString (leavesOf category)))
      (categoriesOf registry);

  # Leaf module paths reachable through the top-level default, which
  # aggregates the category defaults.
  importedOverall = registry:
    sorted (map toString
      (lib.concatMap (categoryDefault: categoryDefault.imports)
        registry.default.imports));

  # Leaf module paths registered across all categories.
  registeredOverall = registry:
    sorted (map toString
      (lib.concatMap leavesOf (builtins.attrValues (categoriesOf registry))));

  # Leaf module files as found on disk under the category directories.
  onDisk = root:
    let
      categories = builtins.attrNames
        (lib.filterAttrs (_: type: type == "directory") (builtins.readDir root));
      isModule = name: type:
        type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix";
      filesIn = category:
        map (file: toString (root + "/${category}/${file}"))
          (builtins.attrNames
            (lib.filterAttrs isModule (builtins.readDir (root + "/${category}"))));
    in
      sorted (lib.concatMap filesIn categories);
in
{
  test_nixos_category_defaults_import_their_leaves = {
    expr = importedByCategory nixosModules;
    expected = registeredByCategory nixosModules;
  };

  test_nixos_default_reaches_every_module = {
    expr = importedOverall nixosModules;
    expected = registeredOverall nixosModules;
  };

  test_nixos_registry_covers_disk = {
    expr = registeredOverall nixosModules;
    expected = onDisk nixosRoot;
  };

  test_home_manager_category_defaults_import_their_leaves = {
    expr = importedByCategory homeModules;
    expected = registeredByCategory homeModules;
  };

  test_home_manager_default_reaches_every_module = {
    expr = importedOverall homeModules;
    expected = registeredOverall homeModules;
  };

  test_home_manager_registry_covers_disk = {
    expr = registeredOverall homeModules;
    expected = onDisk homeRoot;
  };
}
