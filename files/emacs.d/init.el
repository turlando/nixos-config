;;; init.el --- Emacs configuration                   -*- lexical-binding: t -*-

;;; Code:


;; * Preliminaries (constants and path settings)

(defconst emacs-d
  (file-name-directory (file-chase-links load-file-name)))


;; * Package management

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


;; * Mode activation

(defun to/init ()
  ;; Deactivate builtin enabled by default modes
  (menu-bar-mode -1)
  (scroll-bar-mode -1)
  (tool-bar-mode -1)
  (tooltip-mode -1)
  t)

(add-hook 'after-init-hook #'to/init)
