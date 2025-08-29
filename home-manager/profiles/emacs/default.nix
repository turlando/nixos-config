{ ... }:

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

  home.file.".emacs.d/lisp/minimal-early-init.el" = {
    source = ./emacs.d/lisp/minimal-early-init.el;
  };
  home.file.".emacs.d/lisp/minimal-init.el" = {
    source = ./emacs.d/lisp/minimal-init.el;
  };
  home.file.".emacs.d/lisp/turlando-utils.el" = {
    source = ./emacs.d/lisp/turlando-utils.el;
  };

  home.file.".emacs.d/early-init.el" = { source = ./emacs.d/early-init.el; };
  home.file.".emacs.d/init.el" = { source = ./emacs.d/init.el; };
}
