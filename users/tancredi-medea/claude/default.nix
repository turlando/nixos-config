# Claude Code personal configuration for tancredi@medea, via the home-manager
# module. Skills are operational runbooks Claude discovers under ~/.claude/skills
# regardless of the working directory; manage-music-library drives beets on the
# antigone NAS over SSH (see the beets library module in
# users/tancredi-antigone/beets).
#
# The package is pulled from nixpkgs-unstable to keep up with Claude Code's fast
# release cadence.
{ config, ... }:

{
  nixpkgs.unstable.allowUnfree = [ "claude-code" ];

  programs.claude-code = {
    enable = true;
    package = config.nixpkgs.unstable.pkgs.claude-code;
    skills.manage-music-library = ./skills/manage-music-library/SKILL.md;
  };
}
