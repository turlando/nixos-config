;;; post-init.el --- Run after upstream init  -*- lexical-binding: t; -*-

;;; Commentary:
;;; Loaded by minimal-emacs.d's init.el after its own setup.

;;; Code:

(require 'turlando-fonts)
(require 'turlando-utils)

;;;; UI / Appearance

;; Font configuration
(use-package emacs
  :ensure nil
  :init
  (when (display-graphic-p)
    (set-face-attribute 'default nil :font turlando/font-monospace)))

(use-package delight
  :demand t)

(use-package ultra-scroll
  :custom
  (scroll-conservatively 3)
  (scroll-margin 0)
  :config
  (ultra-scroll-mode 1))

(use-package emacs
  :ensure nil
  :custom
  (modus-themes-common-palette-overrides
   '((fringe unspecified)))
  :config
  (load-theme 'modus-operandi-tinted t))

(use-package emacs
  :ensure nil
  :config
  (column-number-mode 1))

(use-package which-key
  :delight
  :demand t
  :config
  (which-key-mode 1)
  :custom
  (which-key-idle-delay 0.3)
  (which-key-sort-order 'which-key-key-order-alpha)
  (which-key-add-column-padding 2)
  (which-key-max-display-columns 3))

(use-package transient)

;;;; Modal Editing

(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-respect-visual-line-mode nil
        evil-undo-system 'undo-redo)
  :config
  (evil-mode 1)
  (global-set-key (kbd "<escape>") 'keyboard-escape-quit))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init)
  :custom
  (evil-collection-want-unimpaired-p nil))

(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-commentary
  :after evil
  :delight
  :config
  (evil-commentary-mode 1))

;;;; Keybindings

(use-package general
  :demand t
  :after evil
  :config
  (general-evil-setup)

  (general-create-definer turlando/universal-leader
    :states '(normal visual emacs)
    :prefix "SPC"
    :global-prefix "M-m"
    :non-normal-prefix "M-m"
    :keymaps 'override)

  (general-create-definer turlando/buffer-leader
    :states '(normal visual emacs)
    :prefix "SPC b"
    :global-prefix "M-m b"
    :non-normal-prefix "M-m b"
    :keymaps 'override)
  (turlando/universal-leader
    "b" '(:ignore t :wk "buffers"))

  (general-create-definer turlando/emacs-leader
    :states '(normal visual emacs)
    :prefix "SPC e"
    :global-prefix "M-m e"
    :non-normal-prefix "M-m e"
    :keymaps 'override)
  (turlando/universal-leader
    "e" '(:ignore t :wk "emacs"))

  (general-create-definer turlando/file-leader
    :states '(normal visual emacs)
    :prefix "SPC f"
    :global-prefix "M-m f"
    :non-normal-prefix "M-m f"
    :keymaps 'override)
  (turlando/universal-leader
    "f" '(:ignore t :wk "files"))

  (general-create-definer turlando/git-leader
    :states '(normal visual emacs)
    :prefix "SPC g"
    :global-prefix "M-m g"
    :non-normal-prefix "M-m g"
    :keymaps 'override)
  (turlando/universal-leader
    "g" '(:ignore t :wk "git"))

  (general-create-definer turlando/help-leader
    :states '(normal visual emacs)
    :prefix "SPC h"
    :global-prefix "M-m h"
    :non-normal-prefix "M-m h"
    :keymaps 'override)
  (turlando/universal-leader
    "h" '(:ignore t :wk "help"))

  (general-create-definer turlando/jump-leader
    :states '(normal visual emacs)
    :prefix "SPC j"
    :global-prefix "M-m j"
    :non-normal-prefix "M-m j"
    :keymaps 'override)
  (turlando/universal-leader
    "j" '(:ignore t :wk "jump"))

  (general-create-definer turlando/parens-leader
    :states '(normal visual emacs)
    :prefix "SPC k"
    :global-prefix "M-m k"
    :non-normal-prefix "M-m k"
    :keymaps 'override)
  (turlando/universal-leader
    "k" '(:ignore t :wk "smartparens"))

  (general-create-definer turlando/project-leader
    :states '(normal visual emacs)
    :prefix "SPC p"
    :global-prefix "M-m p"
    :non-normal-prefix "M-m p"
    :keymaps 'override)
  (turlando/universal-leader
    "p" '(:ignore t :wk "projects"))

  (general-create-definer turlando/search-leader
    :states '(normal visual emacs)
    :prefix "SPC s"
    :global-prefix "M-m s"
    :non-normal-prefix "M-m s"
    :keymaps 'override)
  (turlando/universal-leader
    "s" '(:ignore t :wk "search"))

  (general-create-definer turlando/toggle-leader
    :states '(normal visual emacs)
    :prefix "SPC t"
    :global-prefix "M-m t"
    :non-normal-prefix "M-m t"
    :keymaps 'override)
  (turlando/universal-leader
    "t" '(:ignore t :wk "toggles"))

  (general-create-definer turlando/window-leader
    :states '(normal visual emacs)
    :prefix "SPC w"
    :global-prefix "M-m w"
    :non-normal-prefix "M-m w"
    :keymaps 'override)
  (turlando/universal-leader
    "w" '(:ignore t :wk "windows"))

  (general-create-definer turlando/text-leader
    :states '(normal visual emacs)
    :prefix "SPC x"
    :global-prefix "M-m x"
    :non-normal-prefix "M-m x"
    :keymaps 'override)
  (turlando/universal-leader
    "x" '(:ignore t :wk "text"))

  (general-create-definer turlando/major-leader
    :states '(normal visual emacs)
    :prefix ","
    :global-prefix "M-m m"
    :non-normal-prefix "M-m m"
    :keymaps 'override)
  (turlando/major-leader
    "" '(:ignore t :wk "major mode")))

(use-package emacs
  :ensure nil
  :general
  (turlando/universal-leader
    "SPC" '(execute-extended-command :wk "M-x")
    "TAB" '(evil-switch-to-windows-last-buffer :wk "last buffer")
    ";"   '(eval-expression :wk "eval expression")
    "u"   '(universal-argument :wk "universal arg"))
  (turlando/emacs-leader
    "q" '(save-buffers-kill-terminal :wk "quit emacs")))

;;;; Navigation

;; File operations
(use-package emacs
  :ensure nil
  :general
  (turlando/file-leader
    "c" '(turlando/copy-file :wk "copy file")
    "d" '(dired-jump :wk "dired")
    "D" '(turlando/delete-file :wk "delete file")
    "f" '(find-file :wk "find file")
    "F" '(find-file-at-point :wk "find at point")
    "L" '(consult-locate :wk "locate")
    "r" '(consult-recent-file :wk "recent files")
    "R" '(turlando/rename-file :wk "rename file")
    "s" '(save-buffer :wk "save file")
    "S" '(evil-write-all :wk "save all")
    "y" '(turlando/copy-file-path :wk "copy file path")))

;; Buffer management
(use-package emacs
  :ensure nil
  :general
  (turlando/buffer-leader
    "b" '(consult-buffer :wk "switch buffer")
    "d" '(kill-current-buffer :wk "kill buffer")
    "i" '(ibuffer :wk "ibuffer")
    "k" '(kill-buffer :wk "kill buffer...")
    "n" '(next-buffer :wk "next buffer")
    "p" '(previous-buffer :wk "previous buffer")
    "r" '(revert-buffer :wk "revert buffer")
    "s" '(basic-save-buffer :wk "save buffer")
    "x" '(kill-buffer-and-window :wk "kill buffer + window")
    "y" '(turlando/copy-whole-buffer :wk "copy buffer")
    "Y" '(turlando/copy-buffer-path :wk "copy buffer path")))

;; Window management
(use-package emacs
  :ensure nil
  :demand t
  :config
  (transient-define-prefix
    turlando/window-transient ()
    [["Split"
      ("h" "horizontally" split-window-below :transient t)
      ("v" "vertically" split-window-right :transient t)]
     ["Navigate"
      ("j" "down" windmove-down :transient t)
      ("k" "up" windmove-up :transient t)
      ("l" "right" windmove-right :transient t)
      ("h" "left" windmove-left :transient t)]
     ["Resize"
      ("H" "shrink horizontal" shrink-window-horizontally :transient t)
      ("L" "enlarge horizontal" enlarge-window-horizontally :transient t)
      ("J" "shrink vertical" shrink-window :transient t)
      ("K" "enlarge vertical" enlarge-window :transient t)]
     ["Actions"
      ("d" "delete" delete-window :transient nil)
      ("D" "delete others" delete-other-windows :transient nil)
      ("=" "balance" balance-windows :transient t)
      ("u" "winner undo" winner-undo :transient t)
      ("r" "winner redo" winner-redo :transient t)]])
  :general
  (turlando/window-leader
    "." '(turlando/window-transient :wk "transient")
    "d" '(delete-window :wk "delete window")
    "D" '(delete-other-windows :wk "delete other windows")
    "h" '(split-window-below :wk "split below")
    "u" '(winner-undo :wk "winner undo")
    "U" '(winner-redo :wk "winner redo")
    "v" '(split-window-right :wk "split right")
    "w" '(other-window :wk "other window")))

(use-package winner
  :config (winner-mode 1)
  :general
  (turlando/window-leader
    :keymaps 'winner-mode-map
    "u" '(winner-undo :which-key "Undo Layout")
    "U" '(winner-redo :which-key "Redo Layout")))

(use-package vertico
  :demand t
  :custom
  (vertico-cycle t)
  (vertico-count 15)
  :config
  (require 'vertico-directory)
  (vertico-mode 1)
  :bind
  (:map vertico-map
        ("C-h" . vertico-directory-delete-char)
        ("C-j" . vertico-next)
        ("C-k" . vertico-previous)
        ("C-l" . vertico-insert)))

(use-package orderless
  :demand t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :demand t
  :config
  (marginalia-mode 1))

(use-package consult
  :demand t
  :bind
  (("C-x b" . consult-buffer)
   ("M-y"   . consult-yank-pop))
  :general
  (turlando/jump-leader
    "j" '(consult-imenu :wk "imenu")
    "m" '(consult-mark :wk "marks"))
  (turlando/search-leader
    "b" '(consult-line-multi :wk "search all buffers")
    "h" '(turlando/consult-ripgrep-at-point :wk "search project at point")
    "p" '(consult-ripgrep :wk "search project")
    "s" '(consult-line :wk "search buffer")))

(use-package consult-imenu
  :demand t
  :after consult)

(use-package embark
  :custom
  (embark-prompter 'embark-completing-read-prompter)
  :bind
  (("C-." . embark-act)
   ("M-." . embark-dwim)
   ("C-h B" . embark-bindings))
  :general
  (turlando/help-leader
    "B" '(embark-bindings :wk "embark bindings")))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package dired
  :custom
  (dired-listing-switches "-alh")
  (dired-dwim-target t)
  (dired-recursive-deletes 'always)
  (dired-recursive-copies 'always)
  :general
  (turlando/major-leader
    :keymaps 'dired-mode-map
    "." '(dired-omit-mode :wk "toggle omit")
    "h" '(dired-hide-details-mode :wk "toggle details")
    "s" '(dired-sort-toggle-or-edit :wk "sort")))

(use-package dired-x
  :after dired
  :config
  (setq dired-omit-files "^\\.[^.]\\|^#\\|~$"))

(use-package helpful
  :bind
  (([remap describe-function] . helpful-callable)
   ([remap describe-command] . helpful-command)
   ([remap describe-key] . helpful-key)
   ([remap describe-variable] . helpful-variable))
  :general
  (turlando/help-leader
    "f" '(helpful-callable :wk "describe function")
    "k" '(helpful-key :wk "describe key")
    "m" '(helpful-macro :wk "describe macro")
    "p" '(helpful-at-point :wk "at point")
    "v" '(helpful-variable :wk "describe variable")))

(use-package project
  :ensure nil
  :custom
  (project-switch-commands #'project-dired)
  :general
  (turlando/project-leader
    "b" '(project-switch-to-buffer :wk "switch buffer")
    "c" '(project-compile :wk "compile")
    "d" '(project-dired :wk "dired")
    "f" '(project-find-file :wk "find file")
    "F" '(project-forget-project :wk "forget project")
    "k" '(project-kill-buffers :wk "kill buffers")
    "p" '(project-switch-project :wk "switch project")))

;;;; Editing

(use-package emacs
  :ensure nil
  :config
  (show-paren-mode 1)
  (delete-selection-mode 1)
  (global-auto-revert-mode 1))

(use-package recentf
  :config
  (let ((inhibit-message t))
    (recentf-mode 1)))

(use-package saveplace
  :config
  (save-place-mode 1))

(use-package savehist
  :config
  (savehist-mode 1))

(use-package emacs
  :ensure nil
  :general
  (turlando/text-leader
    "c" '(capitalize-region :wk "capitalize")
    "d" '(delete-duplicate-lines :wk "delete duplicates")
    "l" '(downcase-region :wk "downcase")
    "r" '(reverse-region :wk "reverse")
    "s" '(sort-lines :wk "sort lines")
    "t" '(transpose-words :wk "transpose words")
    "u" '(upcase-region :wk "upcase")))

(use-package emacs
  :ensure nil
  :general
  (turlando/toggle-leader
    "f" '(display-fill-column-indicator-mode :wk "fill column")
    "F" '(auto-fill-mode :wk "auto fill")
    "h" '(hl-line-mode :wk "highlight line")
    "n" '(display-line-numbers-mode :wk "line numbers")
    "w" '(whitespace-mode :wk "whitespace")))

(use-package corfu
  :demand t
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.1)
  :config
  (global-corfu-mode 1)
  :bind
  (:map corfu-map
        ("C-j" . corfu-next)
        ("C-k" . corfu-previous)
        ("C-l" . corfu-insert)
        ("TAB" . corfu-complete)))

(use-package cape
  :demand t
  :config
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

(use-package cape-keyword
  :demand t
  :after cape
  :config
  (add-hook 'completion-at-point-functions #'cape-keyword))

(use-package expand-region
  :general
  (turlando/universal-leader
    "v" '(er/expand-region :wk "expand region")))

(use-package smartparens
  :after transient
  :delight
  :custom
  (sp-base-key-bindings 'paredit)
  (sp-autoskip-closing-pair 'always)
  (sp-hybrid-kill-entire-symbol nil)
  :config
  (require 'smartparens-config)
  (smartparens-global-mode 1)
  (show-smartparens-global-mode 1)
  (transient-define-prefix
    turlando/smartparens-transient ()
    [["Wrap"
      ("w" "wrap" sp-wrap-round :transient t)
      ("W" "unwrap" sp-unwrap-sexp :transient t)]
     ["Slurp"
      ("s" "slurp forward" sp-backward-slurp-sexp :transient t)
      ("S" "slurp backward" sp-forward-slurp-sexp :transient t)]
     ["Barf"
      ("b" "barf forward" sp-forward-barf-sexp :transient t)
      ("B" "barf backward" sp-backward-barf-sexp :transient t)]])
  :general
  (turlando/parens-leader
    "." '(turlando/smartparens-transient :wk "transient")
    "b" '(sp-forward-barf-sexp :wk "barf forward")
    "B" '(sp-backward-barf-sexp :wk "barf backward")
    "c" '(sp-copy-sexp :wk "copy sexp")
    "k" '(sp-kill-sexp :wk "kill sexp")
    "r" '(sp-raise-sexp :wk "raise")
    "s" '(sp-forward-slurp-sexp :wk "slurp forward")
    "S" '(sp-backward-slurp-sexp :wk "slurp backward")
    "t" '(sp-transpose-sexp :wk "transpose")
    "w" '(sp-wrap-round :wk "wrap")
    "W" '(sp-unwrap-sexp :wk "unwrap")))

(use-package avy
  :general
  (turlando/jump-leader
   "c" '(avy-goto-char :wk "jump to char")
   "C" '(avy-goto-char-timer :wk "jump to char (timer)")
   "l" '(avy-goto-line :wk "jump to line")
   "w" '(avy-goto-word-1 :wk "jump to word")))

(use-package editorconfig
  :delight
  :config
  (editorconfig-mode 1))

(use-package highlight-indent-guides
  :delight
  :custom
  (highlight-indent-guides-method 'bitmap)
  (highlight-indent-guides-responsive 'top)
  :general
  (turlando/toggle-leader
    "i" '(highlight-indent-guides-mode :wk "indent guides")))

(use-package aggressive-indent
  :delight
  :custom
  (aggressive-indent-excluded-modes '(html-mode markdown-mode))
  :general
  (turlando/toggle-leader
    "I" '(aggressive-indent-mode :wk "aggressive indent")))

(use-package flymake
  :delight
  :general
  (turlando/toggle-leader
    "e" '(flymake-mode :wk "errors"))
  (turlando/major-leader
    :keymaps 'flymake-mode-map
    "e"  '(:ignore t :wk "errors")
    "eb" '(consult-flymake :wk "buffer diagnostics")
    "en" '(flymake-goto-next-error :wk "next error")
    "ep" '(flymake-goto-prev-error :wk "previous error")
    "eP" '(flymake-show-project-diagnostics :wk "project diagnostics")))

(use-package xref
  :general
  (turlando/jump-leader
   :keymaps 'prog-mode-map
   "b" '(xref-go-back :wk "back")
   "B" '(xref-go-forward :wk "forward")
   "d" '(xref-find-definitions :wk "definition")
   "D" '(xref-find-definitions-other-window :wk "definition other window")
   "r" '(xref-find-references :wk "references")
   "s" '(xref-find-apropos :wk "symbol")))

;;;; Programming

(use-package eldoc
  :delight
  :custom
  (eldoc-idle-delay 0.1)
  (eldoc-echo-area-use-multiline-p nil)
  :init
  (advice-add 'mouse-set-point :after #'turlando/eldoc-after-mouse-click)
  :general
  (turlando/help-leader
    :predicate 'eldoc-mode
    "H" '(eldoc-doc-buffer :wk "documentation buffer")))

(use-package eldoc-box
  :custom
  (eldoc-box-clear-with-C-g t)
  :config
  (defun turlando/eldoc-box-help-at-point ()
    "Show eldoc-box popup; j/k scroll, any other key dismisses."
    (interactive)
    (eldoc-box-help-at-point)
    (set-transient-map
     (let ((map (make-sparse-keymap)))
       (define-key map "j" #'eldoc-box-scroll-up)
       (define-key map "k" #'eldoc-box-scroll-down)
       map)
     t
     #'eldoc-box-quit-frame))
  :general
  (turlando/help-leader
    :predicate 'eldoc-mode
    "h" '(turlando/eldoc-box-help-at-point :wk "documentation popup")))

(use-package eglot
  :custom
  (eglot-autoshutdown t)
  (eglot-code-action-indications nil)
  (eglot-confirm-server-initiated-edits nil)
  (eglot-extend-to-xref t)
  :general
  (turlando/emacs-leader
   :keymaps 'prog-mode-map
   "l"   '(:ignore t :wk "language server")
   "lc"  '(eglot :wk "connect"))
  (turlando/emacs-leader
   :keymaps 'eglot-mode-map
   "ll"  '(eglot-list-connections :wk "list connections")
   "lr"  '(eglot-reconnect :wk "reconnect / restart server")
   "ls"  '(eglot-shutdown :wk "shutdown server"))
  (turlando/jump-leader
   :keymaps 'eglot-mode-map
   "i" '(eglot-find-implementation :wk "implementation")
   "t" '(eglot-find-typeDefinition :wk "type definition"))
  (turlando/major-leader
    :keymaps '(eglot-mode-map evil-visual-state-map)
    "=" '(eglot-format :wk "format region"))
  (turlando/major-leader
    :keymaps '(eglot-mode-map evil-normal-state-map)
    "=" '(eglot-format-buffer :wk "format buffer"))
  (turlando/major-leader
    :keymaps 'eglot-mode-map
    "a" '(eglot-code-actions :wk "code actions")
    "q" '(eglot-code-action-quickfix :wk "quick fix")
    "r" '(eglot-rename :wk "rename"))
  (turlando/toggle-leader
    :keymaps 'eglot-mode-map
    "l" '(eglot-inlay-hints-mode :wk "LSP hints")))

(use-package consult-eglot
  :after (consult eglot)
  :general
  (turlando/jump-leader
   :keymaps 'eglot-mode-map
   "s" '(consult-eglot-symbols :wk "workspace symbol")))

(use-package emacs
  :ensure nil
  :general
  (turlando/major-leader
    :keymaps 'emacs-lisp-mode-map
    "e"  '(:ignore t :wk "eval")
    "eb" '(eval-buffer :wk "buffer")
    "ee" '(eval-last-sexp :wk "last sexp")
    "ef" '(eval-defun :wk "defun")
    "er" '(eval-region :wk "region")))

(use-package just-mode)

(use-package nix-mode
  :mode "\\.nix\\'"
  :hook (nix-mode . eglot-ensure)
  :general
  (turlando/major-leader
    :keymaps 'nix-mode-map
    "f" '(nix-format-buffer :wk "format buffer")))

(use-package rustic
  :mode ("\\.rs\\'" . rustic-mode)
  :hook (rustic-mode . eglot-ensure)
  :custom
  (rustic-format-on-save t)
  (rustic-lsp-client 'eglot)
  :general
  (turlando/major-leader
    :keymaps 'rustic-mode-map
    "c"  '(:ignore t :wk "cargo")
    "cb" '(rustic-cargo-build :wk "build")
    "cc" '(rustic-compile :wk "compile")
    "cd" '(rustic-cargo-doc :wk "doc")
    "cf" '(rustic-cargo-fmt :wk "fmt")
    "ck" '(rustic-cargo-check :wk "check")
    "cl" '(rustic-cargo-clippy :wk "clippy")
    "cr" '(rustic-cargo-run :wk "run")
    "m"  '(rust-toggle-mutability :wk "mut")
    "t"  '(:ignore t :wk "test")
    "ta" '(rustic-cargo-test :wk "test all project")
    "tt" '(rustic-cargo-current-test :wk "test current function")))

(use-package typescript-ts-mode
  :ensure nil
  :mode (("\\.ts\\'" . typescript-ts-mode)
         ("\\.tsx\\'" . tsx-ts-mode)))

(use-package yaml-ts-mode
  :ensure nil
  :mode "\\.ya?ml\\'")

;;;; Version Control

(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  :general
  (turlando/git-leader
    "b" '(magit-blame-addition :wk "blame")
    "c" '(magit-clone :wk "clone")
    "d" '(magit-diff-dwim :wk "diff")
    "f" '(magit-find-file :wk "find file")
    "l" '(magit-log-current :wk "log current")
    "L" '(magit-log-all :wk "log all")
    "s" '(magit-status :wk "status")))

(use-package git-gutter
  :delight
  :hook (prog-mode . git-gutter-mode)
  :custom
  (git-gutter:update-interval 0.5)
  :general
  (turlando/git-leader
    "h" '(git-gutter:popup-hunk :wk "show hunk")
    "n" '(git-gutter:next-hunk :wk "next hunk")
    "p" '(git-gutter:previous-hunk :wk "previous hunk")
    "r" '(git-gutter:revert-hunk :wk "revert hunk"))
  (turlando/toggle-leader
    "g" '(git-gutter-mode :wk "git gutter")))

;;; post-init.el ends here
