{ lib }:

let
  # Stubs for the home-manager options that families.nix consumes. We
  # evaluate the module via lib.evalModules instead of pulling in the
  # full home-manager module set, so any option referenced in
  # families.nix must be declared here.
  stubs = { lib, ... }: {
    options = with lib; {
      home.packages = mkOption {
        type = types.listOf types.package;
        default = [];
      };
      fonts.fontconfig.defaultFonts = {
        monospace = mkOption {
          type = types.listOf types.str;
          default = [];
        };
        sansSerif = mkOption {
          type = types.listOf types.str;
          default = [];
        };
        serif = mkOption {
          type = types.listOf types.str;
          default = [];
        };
      };
    };
  };

  eval = userCfg: (lib.evalModules {
    modules = [
      ../../home-manager/modules/fonts/families.nix
      stubs
      userCfg
    ];
  }).config;

  fakeFont = {
    type = "derivation";
    name = "fake-font";
    outPath = "/nix/store/00000000000000000000000000000000-fake-font";
  };

  aporetic = {
    family = "Aporetic Sans Mono";
    size = 10;
    package = fakeFont;
  };
in
{
  test_null_families_install_no_packages = {
    expr = (eval {}).home.packages;
    expected = [];
  };

  test_null_families_set_no_fontconfig_defaults = {
    expr = (eval {}).fonts.fontconfig.defaultFonts;
    expected = {
      monospace = [];
      sansSerif = [];
      serif = [];
    };
  };

  test_configured_family_installs_its_package = {
    expr = (eval { fonts.families.monospace = aporetic; }).home.packages;
    expected = [ fakeFont ];
  };

  test_configured_family_sets_fontconfig_default = {
    expr = (eval {
      fonts.families.monospace = aporetic;
    }).fonts.fontconfig.defaultFonts.monospace;
    expected = [ "Aporetic Sans Mono" ];
  };

  test_family_without_package_installs_nothing = {
    expr = (eval {
      fonts.families.monospace = { family = "Iosevka"; size = 10; };
    }).home.packages;
    expected = [];
  };

  test_shared_package_is_installed_once = {
    expr = (eval {
      fonts.families.sansSerif = { family = "Fake Sans";  size = 10; package = fakeFont; };
      fonts.families.serif     = { family = "Fake Serif"; size = 10; package = fakeFont; };
    }).home.packages;
    expected = [ fakeFont ];
  };
}
