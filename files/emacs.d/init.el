;;; init.el --- Emacs configuration                   -*- lexical-binding: t -*-

;;; Commentary:

;;; Code:


;;;; Constants and Paths

(defconst emacs-d
  (file-name-directory (file-chase-links load-file-name)))


;;;; Package Management

(defvar early-packages
  '(use-package))

(setq package-archives
      '(("elpa"  . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))

(eval-when-compile
  (dolist (package early-packages)
    (unless (package-installed-p package)
      (package-install package))
    (require package)))

(setq use-package-always-ensure t)


;;;; File Handling

(setq make-backup-files nil)


;;;; Editing

(setq-default fill-column 80
              indent-tabs-mode nil)


;;;; Behaviour

(use-package ivy
  :delight
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
  :custom
  (ivy-initial-inputs-alist nil))

(use-package amx)

(use-package helpful
  :requires counsel
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  (;;([remap describe-function] . helpful-callable) ; Managed by counsel
   ([remap describe-command] . helpful-command)
   ([remap describe-key] . helpful-key)
   ;;([remap describe-variable] . helpful-variable) ; Managed by counsel
   :map help-map
   ("z" . helpful-at-point)))

(use-package which-key
  :requires evil
  :delight ; Doesn't seem to work. Had to use delight manually in init fn.
  :custom
  (which-key-idle-delay 0.3))

(use-package evil
  :init
  (setq evil-undo-system 'undo-redo
        evil-want-integration t     ; Required by evil-collection
        evil-want-keybinding nil))  ; Required by evil-collection

(use-package evil-collection
  :after evil
  :custom
  (evil-collection-mode-list '(ivy whick-key))
  (evil-collection-want-unimpaired-p nil))


;;;; Programming

(use-package eldoc
  :delight)

(use-package nix-mode
  :mode "\\.nix\\'")


;;;; Appearance

(setq inhibit-startup-screen t)

(use-package delight)

(use-package spacemacs-theme
  :defer t ; otherwise it will load spacemacs-theme which does not exist
  :init (load-theme 'spacemacs-dark t))

(set-face-attribute 'default nil
                    :font "Source Code Pro")


;;;; Mode activation

(defun to/init ()
  ;; Deactivate builtin modes enabled by default.
  (menu-bar-mode -1)

  ;; Enable builtin modes disabled by default.
  (column-number-mode 1)

  ;; Enable third-party modes.
  (ivy-mode 1)
  (counsel-mode 1)
  (amx-mode 1)

  (which-key-mode 1)
  (delight 'which-key-mode "" 'which-key) ; Not sure why :delight doesn't work

  (evil-mode 1)
  (evil-collection-init)

  ;; Deactivate builtin modes enabled by default when running with X support.
  (when (display-graphic-p)
    (scroll-bar-mode -1)
    (tool-bar-mode -1)
    (tooltip-mode -1))

  t)

(add-hook 'after-init-hook #'to/init)

;;; init.el ends here
