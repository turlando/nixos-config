;;; init.el --- Emacs configuration                   -*- lexical-binding: t -*-

;;; Commentary:
;; This configuration assumes packages are managed by Nix/home-manager.

;;; Code:

;;;; Performance Optimizations

;; Garbage collection optimization
(setq gc-cons-threshold (* 50 1000 1000))  ; 50mb
(setq gc-cons-percentage 0.6)

;; Increase the amount of data which Emacs reads from the process
(setq read-process-output-max (* 1024 1024)) ; 1mb

;; LSP performance optimizations
;(setq lsp-use-plists t)                      ; Use plists for better performance
; (setq lsp-log-io nil)                       ; Don't log LSP communication

;;;; File Handling

;; Disable backup files to avoid clutter
(setq make-backup-files nil)

;; Auto-save configuration
(setq auto-save-default t
      auto-save-timeout 20
      auto-save-interval 200)

;;;; Editing Defaults

(setq-default
 fill-column 80                    ; Line width for text wrapping
 indent-tabs-mode nil              ; Use spaces instead of tabs
 tab-width 4                       ; Tab width when tabs are displayed
 require-final-newline t)          ; Always end files with newline

;;;; Completion Framework

;; Company mode for auto-completion
(use-package company
  :delight
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay 0.2)          ; Show completions after 0.2s
  (company-minimum-prefix-length 2) ; Start completing after 2 characters
  (company-selection-wrap-around t) ; Wrap around completion list
  :bind
  (:map company-active-map
        ("C-j" . company-select-next)
        ("C-k" . company-select-previous)
        ("C-l" . company-complete-selection)
        ("<tab>" . company-complete-common-or-cycle)))

;;;; LSP Configuration

(use-package lsp-mode
  :init
  ;; Set prefix for lsp-command-keymap
  (setq lsp-keymap-prefix "C-c l")
  :hook 
  ;; Language-specific LSP hooks
  ((rust-mode rustic-mode) . lsp-deferred)  ; Rust
  (go-mode . lsp-deferred)                   ; Go
  (nix-mode . lsp-deferred)                  ; Nix
  (yaml-mode . lsp-deferred)                 ; YAML
  (lsp-mode . lsp-enable-which-key-integration)
  :commands (lsp lsp-deferred)
  :custom
  ;; LSP UI customizations
  (lsp-headerline-breadcrumb-enable nil)    ; Disable breadcrumb in header
  (lsp-signature-auto-activate t)           ; Show function signatures
  (lsp-signature-render-documentation nil)  ; Don't show full docs in signature
  (lsp-eldoc-render-all t)                  ; Show all eldoc info
  (lsp-idle-delay 0.6)                      ; Delay before LSP actions
  (lsp-completion-provider :company)        ; Use company for completion
  ;; Performance tuning
  (lsp-file-watch-threshold 2000)           ; Don't watch too many files
  (lsp-enable-symbol-highlighting t)        ; Highlight symbol at point
  (lsp-enable-on-type-formatting nil)       ; Disable on-type formatting
  (lsp-signature-auto-activate nil))        ; Don't auto-show signatures

(use-package lsp-ui
  :commands lsp-ui-mode
  :custom
  ;; lsp-ui-doc configuration (hover documentation)
  (lsp-ui-doc-enable t)                     ; Enable hover docs
  (lsp-ui-doc-show-with-cursor t)           ; Show docs when cursor stops
  (lsp-ui-doc-delay 0.5)                    ; Delay before showing docs
  (lsp-ui-doc-position 'bottom)             ; Position of doc popup
  (lsp-ui-doc-max-width 120)               ; Max width of doc popup
  (lsp-ui-doc-max-height 30)               ; Max height of doc popup
  ;; lsp-ui-sideline configuration (inline info)
  (lsp-ui-sideline-enable t)                ; Enable sideline info
  (lsp-ui-sideline-show-hover nil)          ; Don't show hover info in sideline
  (lsp-ui-sideline-show-diagnostics t)      ; Show diagnostics in sideline
  (lsp-ui-sideline-show-code-actions t)     ; Show code actions in sideline
  ;; lsp-ui-peek configuration (peek definitions)
  (lsp-ui-peek-enable t)                    ; Enable peek functionality
  (lsp-ui-peek-always-show t))              ; Always show peek window

(use-package lsp-ivy
  :commands lsp-ivy-workspace-symbol
  :after (lsp-mode ivy))

;;;; Syntax Checking

(use-package flycheck
  :delight
  :hook (after-init . global-flycheck-mode)
  :custom
  (flycheck-display-errors-delay 0.3)       ; Show errors after delay
  (flycheck-idle-change-delay 0.6)          ; Check after changes
  :bind
  (:map flycheck-mode-map
        ("C-c f l" . flycheck-list-errors)
        ("C-c f n" . flycheck-next-error)
        ("C-c f p" . flycheck-previous-error)))

;;;; Project Management

(use-package projectile
  :delight
  :init
  (projectile-mode 1)
  :custom
  (projectile-project-search-path '("~/projects" "~/work")) ; Adjust paths as needed
  (projectile-completion-system 'ivy)       ; Use ivy for completion
  (projectile-switch-project-action #'projectile-dired) ; Open dired on switch
  :bind-keymap
  ("C-c p" . projectile-command-map)
  ;:bind
  ;(("f" . projectile-find-file)
  ; ("p" . projectile-switch-project)
  ; ("g" . projectile-grep))
  )

;; Counsel integration with projectile
(use-package counsel-projectile
  :after (counsel projectile)
  :config
  (counsel-projectile-mode 1))

;;;; Version Control

(use-package magit
  :bind ("C-x g" . magit-status)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;; Show git changes in the fringe
(use-package git-gutter
  :delight
  :hook (prog-mode . git-gutter-mode)
  :custom
  (git-gutter:update-interval 0.02))

;;;; EditorConfig Support

(use-package editorconfig
  :delight
  :config
  (editorconfig-mode 1))

;;;; Navigation and Search Framework

(use-package ivy
  :delight
  :config
  (ivy-mode 1)
  :custom
  (ivy-use-virtual-buffers t)               ; Include recent buffers
  (ivy-count-format "(%d/%d) ")             ; Show count in minibuffer
  (ivy-height 15)                           ; Height of ivy minibuffer
  :bind
  (:map ivy-minibuffer-map
        ("C-l" . ivy-alt-done)
        ("C-h" . ivy-backward-delete-char)
        ("C-j" . ivy-next-line)
        ("C-k" . ivy-previous-line)
        ("ESC" . minibuffer-keyboard-quit)
        :map ivy-switch-buffer-map
        ("C-l" . ivy-alt-done)
        ("C-k" . ivy-previous-line)
        ("C-d" . ivy-switch-buffer-kill)))

(use-package counsel
  :delight
  :config
  (counsel-mode 1)
  :custom
  (ivy-initial-inputs-alist nil)            ; Don't start searches with ^
  :bind
  (("M-x" . counsel-M-x)                    ; Enhanced M-x
   ("C-x C-f" . counsel-find-file)          ; Enhanced find-file
   ("C-c k" . counsel-ag)                   ; Search in project
   ("C-s" . counsel-grep-or-swiper)         ; Enhanced search
   ("C-c s" . counsel-ag)))                 ; Search in project

;; Enhanced M-x with better sorting
(use-package amx
  :config
  (amx-mode 1))

;;;; Help System

(use-package helpful
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  (([remap describe-command] . helpful-command)
   ([remap describe-key] . helpful-key)
   :map help-map
   ("z" . helpful-at-point)))

;;;; Keybinding Help

(use-package which-key
  :delight
  :config
  (which-key-mode 1))

;;;; Evil Mode (Vim Emulation)

(use-package evil
  :init
  ;; Evil configuration before loading
  (setq evil-undo-system 'undo-redo
        evil-want-integration t             ; Required by evil-collection
        evil-want-keybinding nil            ; Required by evil-collection
        evil-want-C-u-scroll t              ; Use C-u for scrolling
        evil-want-C-i-jump nil              ; Don't override TAB
        evil-respect-visual-line-mode nil   ; Don't respect visual line mode
        evil-undo-system 'undo-redo)        ; Use built-in undo-redo
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init)
  :custom
  ;; Only enable evil-collection for specific modes to avoid conflicts
  (evil-collection-mode-list '(ivy company lsp-ui-imenu magit))
  (evil-collection-want-unimpaired-p nil))  ; Disable [ and ] bindings

;;;; Language-Specific Configuration

;; Enhanced documentation display
(use-package eldoc
  :delight
  :custom
  (eldoc-idle-delay 0.2)                    ; Show eldoc faster
  (eldoc-echo-area-use-multiline-p nil))    ; Single line eldoc

;; Nix language support
(use-package nix-mode
  :mode "\\.nix\\'"
  :hook (nix-mode . lsp-deferred))          ; Enable LSP for Nix files

;; YAML support  
(use-package yaml-mode
  :hook (yaml-mode . lsp-deferred))         ; Enable LSP for YAML files

;; Rust configuration with enhanced features
(use-package rustic
  :custom
  ;; Rust-specific settings
  (rustic-format-on-save t)                 ; Auto-format on save
  (rustic-lsp-server 'rust-analyzer)        ; Use rust-analyzer as LSP server
  :hook
  ;; Enable various modes for Rust
  (rustic-mode . lsp-deferred)              ; LSP support
  (rustic-mode . flycheck-mode)             ; Syntax checking
  :bind
  (:map rustic-mode-map
        ("C-c C-c l" . flycheck-list-errors) ; List compilation errors
        ("C-c C-c a" . lsp-execute-code-action) ; Execute code actions
        ("C-c C-c r" . lsp-rename)           ; Rename symbol
        ("C-c C-c q" . lsp-workspace-restart) ; Restart LSP workspace
        ("C-c C-c Q" . lsp-workspace-shutdown))) ; Shutdown LSP workspace

;;;; Appearance and UI

;; Disable startup screen
(setq inhibit-startup-screen t)

;; Clean up mode line with delight
(use-package delight)

;; Theme configuration
(use-package spacemacs-theme
  :defer t
  :init 
  (load-theme 'spacemacs-dark t)
  :custom
  ;; Theme customizations
  (spacemacs-theme-org-agenda-height nil)   ; Don't change org agenda height
  (spacemacs-theme-org-height nil))         ; Don't change org heading heights

;; Font configuration
(set-face-attribute
 'default nil
 :font "Source Code Pro-10")

;; Better scrolling
(setq scroll-margin 3                       ; Keep 3 lines visible when scrolling
      scroll-conservatively 101             ; Smooth scrolling
      mouse-wheel-scroll-amount '(1 ((shift) . 1)) ; Smooth mouse wheel
      mouse-wheel-progressive-speed nil)     ; Don't accelerate scrolling

;;;; Window and Buffer Management

;; Winner mode for window configuration undo/redo
(use-package winner
  :config
  (winner-mode 1)
  :bind
  (("C-c w" . winner-undo)
   ("C-c W" . winner-redo)))

;; Better buffer switching with ibuffer
(use-package ibuffer
  :bind ("C-x C-b" . ibuffer)
  :config
  ;; Auto-group buffers by type
  (setq ibuffer-saved-filter-groups
        '(("default"
           ("Dired" (mode . dired-mode))
           ("Org" (name . "^.*org$"))
           ("Git" (mode . magit-mode))
           ("Shell" (or (mode . eshell-mode) (mode . shell-mode)))
           ("Programming" (or
                           (mode . rustic-mode)
                           (mode . rust-mode)
                           (mode . go-mode)
                           (mode . nix-mode)
                           (mode . yaml-mode)))
           ("Emacs" (or
                     (name . "^\\*scratch\\*$")
                     (name . "^\\*Messages\\*$"))))))
  (add-hook 'ibuffer-mode-hook
            (lambda ()
              (ibuffer-auto-mode 1)
              (ibuffer-switch-to-saved-filter-groups "default"))))

;;;; Mode Activation Function

(defun to/init ()
  "Initialize Emacs configuration and enable modes."
  
  ;; Disable unwanted GUI elements
  (menu-bar-mode -1)
  (when (display-graphic-p)
    (scroll-bar-mode -1)
    (tool-bar-mode -1)
    (tooltip-mode -1))

  ;; Enable useful builtin modes
  (column-number-mode 1)                    ; Show column numbers
  (global-auto-revert-mode 1)               ; Auto-refresh changed files
  (delete-selection-mode 1)                 ; Replace selected text when typing
  (electric-pair-mode 1)                    ; Auto-pair brackets
  (show-paren-mode 1)                       ; Highlight matching parentheses
  (setq show-paren-delay 0)                 ; No delay for paren highlighting

  ;; Display startup time
  (message
   "Emacs ready in %s with %d garbage collections."
   (format
    "%.2f seconds"
    (float-time
     (time-subtract after-init-time before-init-time)))
   gcs-done)

  t)

(add-hook 'after-init-hook #'to/init)

;;; init.el ends here
