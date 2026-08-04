# Tancredi's Claude Code extras on top of the shared claude-code profile: the
# manage-music-library skill, which drives beets on the antigone NAS over SSH.
# See the beets library module in users/tancredi-antigone/beets.
_:

{
  programs.claude-code = {
    enable = true;
    skills.manage-music-library = ./skills/manage-music-library/SKILL.md;
  };
}
