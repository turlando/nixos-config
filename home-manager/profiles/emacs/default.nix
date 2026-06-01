{ pkgs, ... }:

{
  home.packages = [ pkgs.ripgrep ];

  programs.emacs = {
    extraPackages = epkgs: with epkgs; [
      aggressive-indent
      avy
      company
      consult
      delight
      editorconfig
      evil
      evil-collection
      evil-commentary
      evil-surround
      expand-region
      general
      git-gutter
      helpful
      highlight-indent-guides
      just-mode
      magit
      marginalia
      nix-mode
      orderless
      projectile
      rustic
      smartparens
      spacemacs-theme
      (treesit-grammars.with-grammars (p: [
        p.tree-sitter-tsx
        p.tree-sitter-typescript
        p.tree-sitter-yaml
      ]))
      ultra-scroll
      vertico
      which-key
      yaml-mode
    ];
  };

  xdg.configFile."emacs/early-init.el".source = ./config/early-init.el;
  xdg.configFile."emacs/init.el".source = ./config/init.el;
  xdg.configFile."emacs/lisp/minimal-early-init.el".source =
    ./config/lisp/minimal-early-init.el;
  xdg.configFile."emacs/lisp/minimal-init.el".source =
    ./config/lisp/minimal-init.el;
  xdg.configFile."emacs/lisp/turlando-utils.el".source =
    ./config/lisp/turlando-utils.el;
}
