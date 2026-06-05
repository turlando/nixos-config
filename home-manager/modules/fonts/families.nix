{ config, lib, pkgs, ... }:

let
  inherit (lib) filter literalExpression mkOption types unique;

  cfg = config.fonts.families;

  fontFamilyType = types.submodule {
    options = {
      family = mkOption {
        type = types.str;
        description = "Font family name as fontconfig sees it.";
      };

      size = mkOption {
        type = types.numbers.positive;
        description = "Default size in points for this family.";
      };

      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = ''
          Optional package providing this font. When non-null, it is
          added to home.packages so the font is installed alongside the
          configuration that names it.
        '';
      };
    };
  };
in {
  options.fonts.families = {
    monospace = mkOption {
      type = fontFamilyType;
      default = {
        family = "Noto Sans Mono";
        size = 10;
        package = pkgs.noto-fonts;
      };
      example = literalExpression ''
        {
          family = "Aporetic Sans Mono";
          size = 10;
          package = pkgs.aporetic;
        }
      '';
      description = "Monospace font (for code editors and terminals).";
    };

    sansSerif = mkOption {
      type = fontFamilyType;
      default = {
        family = "Noto Sans";
        size = 10;
        package = pkgs.noto-fonts;
      };
      example = literalExpression ''
        {
          family = "Aporetic Sans";
          size = 11;
          package = pkgs.aporetic;
        }
      '';
      description = "Sans-serif font.";
    };

    serif = mkOption {
      type = fontFamilyType;
      default = {
        family = "Noto Serif";
        size = 10;
        package = pkgs.noto-fonts;
      };
      example = literalExpression ''
        {
          family = "Aporetic Serif";
          size = 11;
          package = pkgs.aporetic;
        }
      '';
      description = "Serif font.";
    };
  };

  config = {
    home.packages = unique (filter (p: p != null) [
      cfg.monospace.package
      cfg.sansSerif.package
      cfg.serif.package
    ]);

    fonts.fontconfig.defaultFonts.monospace = [ cfg.monospace.family ];
    fonts.fontconfig.defaultFonts.sansSerif = [ cfg.sansSerif.family ];
    fonts.fontconfig.defaultFonts.serif     = [ cfg.serif.family ];
  };
}
