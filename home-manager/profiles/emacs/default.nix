_:

{
  programs.emacs = {
    extraPackages = epkgs: with epkgs; [
      aggressive-indent
      amx
      avy
      company
      counsel
      counsel-projectile
      delight
      editorconfig
      evil
      evil-collection
      expand-region
      flycheck
      general
      git-gutter
      helpful
      highlight-indent-guides
      ivy
      just-mode
      magit
      nix-mode
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
