(require 'dss-paths)
(require 'ediff)
(require 'ediff-vers)
(require 'vc)
(require 'magit)

(setq dvc-tips-enabled nil)
(setq vc-follow-symlinks t)

(defun vc-ediff ()
  (interactive)
  (vc-buffer-sync)
  (ediff-load-version-control)
  (setq ediff-split-window-function 'split-window-horizontally)
  (ediff-vc-internal "" ""))

(defun dss/vc-state-refresh-open-buffers ()
  (interactive)
  (message "updating buffer VC status ...")
  (mapc (lambda (b)
          (dss/vc-state-refresh (buffer-file-name b)))
        (buffer-list))
  (message ""))

(defun dss/vc-state-refresh (file &optional backend)
  (interactive)
  (when (> (length file) 0)
    (setq backend (or backend (vc-backend file)))
    (when backend
      (vc-state-refresh file backend))))

(provide 'dss-vc)
