# Tancredi's Claude Code extras on top of the shared claude-code profile: the
# manage-music-library skill (drives beets on the antigone NAS over SSH; see
# the beets library module in users/tancredi-antigone/beets) and personal
# settings that merge into settings.json.
_:

{
  programs.claude-code = {
    enable = true;
    skills.manage-music-library = ./skills/manage-music-library/SKILL.md;

    settings = {
      model = "claude-fable-5[1m]";
      verbose = true;
    };
  };
}
