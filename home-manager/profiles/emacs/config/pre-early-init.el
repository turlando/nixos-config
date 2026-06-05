;;; pre-early-init.el --- Run before upstream early-init  -*- lexical-binding: t; -*-

;;; Commentary:
;;; Loaded by minimal-emacs.d's early-init.el before its own setup.

;;; Code:

;; Nix manages packages; skip upstream's package.el bootstrap.
(setq minimal-emacs-package-initialize-and-refresh nil)

(add-to-list 'load-path (locate-user-emacs-file "lisp/"))

(provide 'pre-early-init)
;;; pre-early-init.el ends here
