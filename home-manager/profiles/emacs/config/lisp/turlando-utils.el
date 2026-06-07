;;; turlando-utils.el --- Misc helpers               -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:

;;;; Predicates

(defun turlando/buffer-file-or-error ()
  "Return the current buffer's file path, signaling `user-error' if none."
  (or (buffer-file-name)
      (user-error "Current buffer is not visiting a file")))

;;;; Buffer / file copy

(defun turlando/copy-whole-buffer ()
  "Copy entire buffer to kill ring."
  (interactive)
  (kill-new (buffer-substring-no-properties (point-min) (point-max)))
  (message "Buffer copied"))

(defun turlando/copy-buffer-path ()
  "Copy the current buffer's file path to kill ring."
  (interactive)
  (let ((filename (turlando/buffer-file-or-error)))
    (kill-new filename)
    (message "Copied: %s" filename)))

(defun turlando/copy-file (new-path)
  "Copy the current buffer's file to NEW-PATH.
Prompt before overwriting an existing file."
  (interactive "FCopy file to: ")
  (let ((filename (turlando/buffer-file-or-error)))
    (when (or (not (file-exists-p new-path))
              (yes-or-no-p (format "Overwrite '%s'? " new-path)))
      (copy-file filename new-path t)
      (message "Copied %s to %s" filename new-path))))

;;;; File rename / delete

(defun turlando/rename-file ()
  "Rename current buffer and the file it is visiting."
  (interactive)
  (let* ((filename (turlando/buffer-file-or-error))
         (basename (file-name-nondirectory filename))
         (new-name (read-file-name
                    "New name: "
                    (file-name-directory filename)
                    basename nil basename)))
    (when (get-file-buffer new-name)
      (user-error "A buffer is already visiting '%s'" new-name))
    (let ((directory (file-name-directory new-name)))
      (when (and (not (file-exists-p directory))
                 (yes-or-no-p (format "Create directory '%s'? " directory)))
        (make-directory directory t)))
    (rename-visited-file new-name)
    (when (fboundp 'recentf-add-file)
      (recentf-add-file new-name)
      (recentf-remove-if-non-kept filename))
    (message "Renamed '%s' to '%s'"
             basename
             (file-name-nondirectory new-name))))

(defun turlando/delete-file ()
  "Delete the file the current buffer is visiting and kill the buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (name (buffer-name)))
    (cond
     ((not (and filename (file-exists-p filename)))
      (kill-current-buffer))
     ((yes-or-no-p (format "Delete file '%s'? " name))
      (delete-file filename t)
      (kill-current-buffer)
      (message "Deleted '%s'" filename))
     (t (message "Canceled deletion")))))

;;;; Search

(defun turlando/consult-ripgrep-at-point ()
  "Search project with ripgrep, prefilled with the symbol at point."
  (interactive)
  (consult-ripgrep nil (thing-at-point 'symbol t)))

;;;; Eldoc

(defun turlando/eldoc-after-mouse-click (&rest _)
  "Schedule an eldoc query after a mouse click.
On PGTK Emacs the eldoc idle timer doesn't fire after mouse events.
Invalidates `eldoc--last-request-state' so the non-interactive call
actually runs the query (echo area only; the doc buffer would pop up
if we forced interactive mode)."
  (when (bound-and-true-p eldoc-mode)
    (run-at-time eldoc-idle-delay nil
                 (lambda ()
                   (setq eldoc--last-request-state nil)
                   (eldoc-print-current-symbol-info)))))

;;;; UI

(defun turlando/apply-default-font (&optional frame)
  "Apply the configured monospace font to FRAME (or the current one).
Required for `emacs --daemon': the initial daemon has no graphical
frame, so `display-graphic-p' is nil at startup and the font would
never be applied to subsequently-created frames."
  (when (display-graphic-p frame)
    (set-face-attribute 'default frame :font turlando/font-monospace)))

(provide 'turlando-utils)
;;; turlando-utils.el ends here
