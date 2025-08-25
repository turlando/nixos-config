{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption types;
in {
  options.i18n.extra-locale = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "it_IT.UTF-8";
    description = ''
      If set, applies the given locale to a group of secondary locale categories:

      - `LC_MEASUREMENT`
      - `LC_MONETARY`
      - `LC_NAME`
      - `LC_NUMERIC`
      - `LC_PAPER`
      - `LC_TELEPHONE`
      - `LC_TIME`

      This is useful if you want a consistent regional format (dates,
      numbers, paper size, etc.) that differs from `i18n.defaultLocale`.

      Example:

      ```
      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extra-locale = "it_IT.UTF-8";
      ```

      In this example, messages and interface text will be in American English,
      while formatting, measurement units, and related categories follow Italian
      conventions.
    '';
  };

  config = mkIf (config.i18n.extra-locale != null) {
    environment.sessionVariables = {
      LC_MEASUREMENT = config.i18n.extra-locale;
      LC_MONETARY    = config.i18n.extra-locale;
      LC_NAME        = config.i18n.extra-locale;
      LC_NUMERIC     = config.i18n.extra-locale;
      LC_PAPER       = config.i18n.extra-locale;
      LC_TELEPHONE   = config.i18n.extra-locale;
      LC_TIME        = config.i18n.extra-locale;
    };
  };
}
