# Index of option modules, grouped by category; leaves are file paths so
# the module system can identify and deduplicate each module by file. Each
# category exports a default importing everything under it, and the
# top-level default aggregates the category defaults. An option module only
# declares options, so a host carries the whole set and takes effect only
# from the options it sets. tests/modules/index.nix keeps the defaults, the
# index, and the files on disk in sync.
let
  boot = import ./boot;
  environment = import ./environment;
  hardware = import ./hardware;
  i18n = import ./i18n;
  services = import ./services;
in
{
  inherit boot environment hardware i18n services;
  default.imports = [
    boot.default
    environment.default
    hardware.default
    i18n.default
    services.default
  ];
}
