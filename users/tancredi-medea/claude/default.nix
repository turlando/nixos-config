{ config, pkgs, ... }:
let
  # Claude Code consults $BROWSER before the desktop default whenever it opens
  # a URL: the OAuth callback at login, artifact and Design canvas links, and
  # MCP server authentication. Pinning it to the luminovo Firefox profile gives
  # this account a claude.ai session of its own.
  claude-browser = let
    firefox = config.programs.firefox.finalPackage;
    profile = config.programs.firefox.profiles.luminovo.name;
  in pkgs.writeShellScriptBin "claude-browser" ''
    exec ${firefox}/bin/firefox -P ${profile} --new-tab "$@"
  '';
in {
  programs.claude-code = {
    enable = true;
    skills.manage-music-library = ./skills/manage-music-library/SKILL.md;

    settings = {
      env.BROWSER = "${claude-browser}/bin/claude-browser";

      # claude.ai connectors hang off the Claude account rather than the
      # installation, so Luminovo's Notion, Slack and data warehouse follow
      # into this session regardless of the UNIX user. Drop them all and reach
      # MCP servers through the configuration below instead; /mcp can suppress
      # connectors one by one should any of them become worth keeping.
      disableClaudeAiConnectors = true;
    };

    # Notion's hosted MCP endpoint, authenticated once from /mcp against the
    # personal workspace. home-manager delivers it as a plugin carrying a
    # .mcp.json, passed to the CLI with --plugin-dir.
    mcpServers.notion = {
      type = "http";
      url = "https://mcp.notion.com/mcp";
    };
  };
}
