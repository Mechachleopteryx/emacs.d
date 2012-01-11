(require 'ibuffer)
(defalias 'list-buffers 'ibuffer)

(require 'ibuffer-vc)
(setq ibuffer-formats
      '(
        (mark dss-modified vc-status-mini " "
              (name 35 35 :left :elide)
              ;; " " (mode 10 10 :left :elide)
              " " filename-and-process)
        ;; (mark modified read-only " " (name 18 18 :left :elide)
        ;;       " " (size 9 -1 :right)
        ;;       " " (mode 16 16 :left :elide) " " filename-and-process)
        (mark " " (name 16 -1) " " filename)))

(define-ibuffer-column dss-modified (:name "M" :inline t)
  (if (buffer-modified-p)
      (propertize "-" 'face '(:foreground "magenta"))
    " "))

;;; https://github.com/mattkeller/mk-project/
;;; http://www.littleredbat.net/mk/blog/story/85/ ibuffer filter by project

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'window-numbering)
(window-numbering-mode 1)
;; (setq window-numbering-assign-func
;;       (lambda () (when (equal (buffer-name) "*Calculator*") 9)))

;;; http://stackoverflow.com/questions/2081577/setting-emacs-split-to-horizontal
;;; turns out this isn't very usable in practice. The default settings are best.
;; (setq split-height-threshold nil) ; 80
;; (setq split-width-threshold 0) ; 160

(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)
(setq uniquify-ignore-buffers-re "^\\*") ; don't muck with special buffers

(when (fboundp 'winner-mode)
      (winner-mode 1))


; http://dfan.org/blog/2009/02/19/emacs-dedicated-windows/
(defun dss/toggle-current-window-dedication ()
 (interactive)
 (let* ((window    (selected-window))
        (dedicated (window-dedicated-p window)))
   (set-window-dedicated-p window (not dedicated))
   (message "Window %sdedicated to %s"
            (if dedicated "no longer " "")
            (buffer-name))))


;;; http://www.emacswiki.org/emacs/ToggleWindowSplit
(defun dss/toggle-window-split ()
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
             (next-win-buffer (window-buffer (next-window)))
             (this-win-edges (window-edges (selected-window)))
             (next-win-edges (window-edges (next-window)))
             (this-win-2nd (not (and (<= (car this-win-edges)
                                         (car next-win-edges))
                                     (<= (cadr this-win-edges)
                                         (cadr next-win-edges)))))
             (splitter
              (if (= (car this-win-edges)
                     (car (window-edges (next-window))))
                  'split-window-horizontally
                'split-window-vertically)))
        (delete-other-windows)
        (let ((first-win (selected-window)))
          (funcall splitter)
          (if this-win-2nd (other-window 1))
          (set-window-buffer (selected-window) this-win-buffer)
          (set-window-buffer (next-window) next-win-buffer)
          (select-window first-win)
          (if this-win-2nd (other-window 1))))))

;;; http://www.emacswiki.org/emacs/TransposeWindows
(defun dss/transpose-windows (arg)
  "Transpose the buffers shown in two windows."
  (interactive "p")
  (let ((selector (if (>= arg 0) 'next-window 'previous-window)))
    (while (/= arg 0)
      (let ((this-win (window-buffer))
            (next-win (window-buffer (funcall selector))))
        (set-window-buffer (selected-window) next-win)
        (set-window-buffer (funcall selector) this-win)
        (select-window (funcall selector)))
      (setq arg (if (plusp arg) (1- arg) (1+ arg))))))

;;; http://www.emacswiki.org/emacs/TransposeWindows
(defun dss/rotate-windows ()
  "Rotate your windows"
  (interactive)
  (cond
   ((not (> (count-windows) 1))
    (message "You can't rotate a single window!"))
   (t
    (let ((i 1)
          (num-windows (count-windows)))
      (while  (< i num-windows)
        (let* ((w1 (elt (window-list) i))
               (w2 (elt (window-list) (+ (% i num-windows) 1)))
               (b1 (window-buffer w1))
               (b2 (window-buffer w2))
               (s1 (window-start w1))
               (s2 (window-start w2)))
          (set-window-buffer w1 b2)
          (set-window-buffer w2 b1)
          (set-window-start w1 s2)
          (set-window-start w2 s1)
          (setq i (1+ i))))))))

(defun dss/sync-point-all-windows ()
  (interactive)
  (mapc '(lambda (f)
           (mapc '(lambda (w)
                    (if (eq (window-buffer w)
                            (current-buffer))
                        (set-window-point w (point))))
                 (window-list f)))
        (frame-list)))

(defun dss/frame-by-name (name)
  (car (delq nil
             (mapcar (lambda (fr) (if (string= (frame-parameter fr 'name) name) fr))
                     (frame-list)))))

(defun dss/window-list ()
  (interactive)
  (mapc #'(lambda (f)
           (insert (format "%S\n" f))
           (let ((selectedw (frame-selected-window f)))
             (mapc '(lambda (w)
                      (if (eq w selectedw)
                          (insert "*"))
                      (insert (format "  %S" w))
                      (insert (format "  %s" (buffer-name (window-buffer w))))
                      (insert (format ":%S\n" (window-point w))))
                   (window-list f))))
        (frame-list)))

;;; get-buffer-window-list
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dss/kill-clean-buffer ()
  (interactive)
  (let ((buf (current-buffer)))
    (and buf (not (buffer-modified-p buf))
         (kill-buffer buf))))

(defun dss/kill-buffer ()
  (interactive)
  (let ((buf (current-buffer)))
    (kill-buffer buf)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'dss-buffer-and-window-handling)
