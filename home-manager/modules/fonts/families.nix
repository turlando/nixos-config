{ config, lib, ... }:

let
  inherit (lib) filter literalExpression mkIf mkOption types unique;

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
      type = types.nullOr fontFamilyType;
      default = null;
      example = literalExpression ''
        {
          family = "Aporetic Sans Mono";
          size = 10;
          package = pkgs.aporetic;
        }
      '';
      description = ''
        Monospace font (for code editors and terminals). When null, no
        package is installed and no fontconfig default is set.
      '';
    };

    sansSerif = mkOption {
      type = types.nullOr fontFamilyType;
      default = null;
      example = literalExpression ''
        {
          family = "Aporetic Sans";
          size = 11;
          package = pkgs.aporetic;
        }
      '';
      description = ''
        Sans-serif font. When null, no package is installed and no
        fontconfig default is set.
      '';
    };

    serif = mkOption {
      type = types.nullOr fontFamilyType;
      default = null;
      example = literalExpression ''
        {
          family = "Aporetic Serif";
          size = 11;
          package = pkgs.aporetic;
        }
      '';
      description = ''
        Serif font. When null, no package is installed and no fontconfig
        default is set.
      '';
    };
  };

  config = {
    home.packages =
      let
        families = filter (family: family != null)
          [ cfg.monospace cfg.sansSerif cfg.serif ];
      in
        unique (filter (package: package != null)
          (map (family: family.package) families));

    fonts.fontconfig.defaultFonts = {
      monospace = mkIf (cfg.monospace != null) [ cfg.monospace.family ];
      sansSerif = mkIf (cfg.sansSerif != null) [ cfg.sansSerif.family ];
      serif     = mkIf (cfg.serif     != null) [ cfg.serif.family ];
    };
  };
}
