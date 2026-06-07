;;; turlando-utils.el --- Misc helpers               -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:

(defun turlando/copy-whole-buffer ()
  "Copy entire buffer to kill ring."
  (interactive)
  (kill-new (buffer-substring-no-properties (point-min) (point-max)))
  (message "Buffer copied"))

(defun turlando/copy-buffer-path ()
  "Copy the current buffer's file path to kill ring."
  (interactive)
  (if-let* ((filename (buffer-file-name)))
      (progn
        (kill-new filename)
        (message "Copied: %s" filename))
    (error "Buffer is not visiting a file")))

(defun turlando/copy-file (new-path)
  "Copy the current buffer's file to NEW-PATH."
  (interactive "FCopy file to: ")
  (let ((filename (buffer-file-name)))
    (if (not filename)
        (error "Current buffer is not visiting a file")
      (copy-file filename new-path t)
      (message "Copied %s to %s" filename new-path))))

(defun turlando/rename-file ()
  "Rename current buffer and file it is visiting."
  (interactive)
  (let* ((name (buffer-name))
         (filename (buffer-file-name))
         (basename (file-name-nondirectory filename)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name
                       "New name: "
                       (file-name-directory filename)
                       basename nil basename)))
        (if (get-buffer new-name)
            (error "A buffer named '%s' already exists!" new-name)
          (let ((directory (file-name-directory new-name)))
            (when (and (not (file-exists-p directory))
                       (yes-or-no-p (format "Create directory '%s'?" directory)))
              (make-directory directory t))
            (rename-file filename new-name 1)
            (rename-buffer new-name)
            (set-visited-file-name new-name)
            (set-buffer-modified-p nil)
            (when (fboundp 'recentf-add-file)
              (recentf-add-file new-name)
              (recentf-remove-if-non-kept filename))
            (message "File '%s' successfully renamed to '%s'"
                     name (file-name-nondirectory new-name))))))))

(defun turlando/consult-ripgrep-at-point ()
  "Search project with ripgrep, prefilled with the symbol at point."
  (interactive)
  (consult-ripgrep nil (thing-at-point 'symbol t)))

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

(defun turlando/apply-default-font (&optional frame)
  "Apply the configured monospace font to FRAME (or the current one).
Required for `emacs --daemon': the initial daemon has no graphical
frame, so `display-graphic-p' is nil at startup and the font would
never be applied to subsequently-created frames."
  (when (display-graphic-p frame)
    (set-face-attribute 'default frame :font turlando/font-monospace)))

(defun turlando/delete-file ()
  "Remove file connected to current buffer and kill buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (if (not (and filename (file-exists-p filename)))
        (kill-current-buffer)
      (if (yes-or-no-p (format "Delete file '%s'?" name))
          (progn
            (delete-file filename t)
            (kill-buffer buffer)
            (message "File deleted: '%s'" filename))
        (message "Canceled file deletion")))))

(provide 'turlando-utils)
;;; turlando-utils.el ends here
