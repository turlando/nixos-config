{ ... }:

{
  programs.emacs = {
    extraConfig = builtins.readFile ./init.el;

    extraPackages = epkgs: with epkgs; [
      # Core packages that benefit from Nix management
      use-package
      
      # LSP and completion
      lsp-mode
      lsp-ui
      lsp-ivy
      company
      flycheck
      
      # Language-specific packages
      rustic
      nix-mode
      yaml-mode
      
      # Editor enhancements
      ivy
      counsel
      amx
      helpful
      which-key
      evil
      evil-collection
      editorconfig
      projectile
      counsel-projectile
      magit
      git-gutter
      
      # Appearance
      delight
      spacemacs-theme
    ];
  };
}
