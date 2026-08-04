{ config, ... }:

{
  nixpkgs.unstable.allowUnfree = [ "claude-code" ];

  programs.claude-code = {
    package = config.nixpkgs.unstable.pkgs.claude-code;

    settings = {
      model = "claude-opus-5[1m]";
      effortLevel = "xhigh";

      tui = "fullscreen";
      theme = "dark";

      # Show full tool output rather than truncated summaries.
      verbose = true;

      # Retain chat transcripts well past the 30-day default so old
      # conversations stay resumable.
      cleanupPeriodDays = 365;

      extraKnownMarketplaces.claude-plugins-official.source = {
        source = "github";
        repo = "anthropics/claude-plugins-official";
      };

      enabledPlugins."rust-analyzer-lsp@claude-plugins-official" = true;
    };
  };
}
