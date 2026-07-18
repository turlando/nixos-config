# Index of option modules, grouped by category; leaves are file paths so
# the module system can identify and deduplicate each module by file. Each
# category exports a default importing everything under it, and the
# top-level default aggregates the category defaults. An option module only
# declares options, so a configuration carries the whole set and takes
# effect only from the options it sets. tests/modules/index.nix keeps the
# defaults, the index, and the files on disk in sync.
let
  environment = import ./environment;
  fonts = import ./fonts;
  programs = import ./programs;
in
{
  inherit environment fonts programs;
  default.imports = [
    environment.default
    fonts.default
    programs.default
  ];
}
