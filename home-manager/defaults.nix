{ lib, config, ... }:

let
  inherit (lib) mkIf mkOption types;
  inherit (lib.files) getFile;
in

{
  options.environment.defaults.enable = mkOption {
    type = types.bool;
    default = false;
    example = true;
  };

  config = mkIf config.environment.defaults.enable {
    programs.git = {
      enable = true;
      aliases = {
        a  = "add";
        b  = "branch";
        c  = "commit";
        cm = "commit -m";
        co = "checkout";
        cb = "checkout -b";
        d  = "diff";
        ds = "diff --staged";
        h  = "log --graph --date=short --pretty=format:'%Cred%h%Creset %Cgreen%ad%Creset %s%d %Cblue%an%Creset'";
        r  = "rebase";
        ri = "rebase -i";
        s  = "status";
        st = "stash";
        sp = "stash pop";
        u  = "remote update";
      };
      extraConfig = {
        merge = { ff = "only"; };
        pull = { ff = "only"; };
      };
    };

    programs.emacs.enable = true;
    home.file.".emacs.d" = { source = getFile /emacs.d; recursive = true; };
  };
}
