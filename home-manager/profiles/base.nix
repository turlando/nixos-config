{ ...}:

{
  programs.git.enable = true;
  programs.git.aliases = {
    a  = "add";
    b  = "branch";
    c  = "commit";
    cm = "commit -m";
    co = "checkout";
    cb = "checkout -b";
    d  = "diff";
    ds = "diff --staged";
    h  = ''
      log                                                                        \
        --graph                                                                  \
        --date=short                                                             \
        --pretty=format:'%Cred%h%Creset %Cgreen%ad%Creset %s%d %Cblue%an%Creset'
    '';
    r  = "rebase";
    ri = "rebase -i";
    s  = "status";
    st = "stash";
    sp = "stash pop";
    u  = "remote update";
  };
  programs.git.extraConfig = {
    merge = { ff = "only"; };
    pull = { ff = "only"; };
  };
}
