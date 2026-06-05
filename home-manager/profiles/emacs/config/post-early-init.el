;;; post-early-init.el --- Run after upstream early-init  -*- lexical-binding: t; -*-

;;; Commentary:
;;; Loaded by minimal-emacs.d's early-init.el after its own setup.

;;; Code:

;; Nix manages packages; don't let use-package install them.
(setq use-package-always-ensure nil)

(provide 'post-early-init)
;;; post-early-init.el ends here
