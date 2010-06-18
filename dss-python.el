;; python-mode
(add-to-list 'load-path "/usr/share/emacs/site-lisp/python-mode")
(autoload 'python-mode "python-mode" "PY" t)


(add-to-list 'auto-mode-alist '("\\.py$" . python-mode))
(add-to-list 'interpreter-mode-alist '("python" . python-mode))

(setq pycodechecker "dss_pycheck") ; this is a wrapper around pep8.py, pyflakes and pylint
(when (load "flymake" t)
  (load-library "flymake-cursor")
  (defun flymake-pycodecheck-init ()
    (let* ((temp-file (flymake-init-create-temp-buffer-copy
                       'flymake-create-temp-inplace))
           (local-file (file-relative-name
                        temp-file
                        (file-name-directory buffer-file-name))))
      (list pycodechecker (list local-file))))
  (add-to-list 'flymake-allowed-file-name-masks
               '("\\.py\\'" flymake-pycodecheck-init)))
(defun dss/pylint-msgid-at-point ()
  (interactive)
  (let (msgid
        (line-no (line-number-at-pos)))
    (dolist (elem flymake-err-info msgid)
      (if (eq (car elem) line-no)
            (let ((err (car (second elem))))
              (setq msgid (second (split-string (flymake-ler-text err)))))))))

(defun dss/pylint-silence (msgid)
  "Add a special pylint comment to silence a particular warning."
  (interactive (list (read-from-minibuffer "msgid: " (dss/pylint-msgid-at-point))))
  (save-excursion
    (comment-dwim nil)
    (if (looking-at "pylint:")
        (progn (end-of-line)
               (insert ","))
        (insert "pylint: disable-msg="))
    (insert msgid)))

(defun dss/out-sexp (&optional level forward syntax)
  "Skip out of any nested brackets.
 Skip forward if FORWARD is non-nil, else backward.
 If SYNTAX is non-nil it is the state returned by `syntax-ppss' at point.
 Return non-nil if and only if skipping was done."
  (interactive)
  (if (dss/in-string-p)
      (dss/beginning-of-string))
  (progn
    (let* ((depth (syntax-ppss-depth (or syntax (syntax-ppss))))
          (level (or level depth))
          (forward (if forward -1 1)))
      (unless (zerop depth)
        (if (> depth 0)
            ;; Skip forward out of nested brackets.
            (condition-case ()            ; beware invalid syntax
                (progn (backward-up-list (* forward level)) t)
              (error nil))
          ;; Invalid syntax (too many closed brackets).
          ;; Skip out of as many as possible.
          (let (done)
            (while (condition-case ()
                       (progn (backward-up-list forward)
                              (setq done t))
                     (error nil)))
            done))))))

(defun dss/out-one-sexp (&optional forward)
  (interactive)
  (dss/out-sexp 1 forward))

(defun dss/out-one-sexp-forward ()
  (interactive)
  (dss/out-sexp 1 1))

(defun dss/py-insert-docstring ()
  (interactive)
  (if (not (save-excursion
             (forward-line 1)
             (back-to-indentation)
             (looking-at "[\"']")))
      (save-excursion
        (end-of-line)
        (open-line 1)
        (forward-line 1)
        (py-indent-line)
        (insert "\"\"\"\n")
        (py-indent-line)
        (insert "\"\"\"")))
  (progn
    (forward-line 1)
    (end-of-line)))

(defun dss/py-insert-triple-quote ()
  (interactive)
  (insert "\"\"\"")
  (save-excursion (insert " \"\"\"")))

(defun dss/py-fix-indent (top bottom)
  (interactive "r")
  (apply-macro-to-region-lines top bottom (kbd "TAB")))

(defun dss/py-fix-last-utterance ()
  "Downcase the previous word and remove any leading whitespace.
This is useful with Dragon NaturallySpeaking."
  (interactive)
  (save-excursion
    (backward-word)
    (set-mark (point))
    (call-interactively 'py-forward-into-nomenclature)
    (call-interactively 'downcase-region)
    (setq mark-active nil)
    (backward-word)
    (delete-horizontal-space t)))

(defun dss/py-dot-dictate (words)
  (interactive "s")
  (progn
    (if (looking-at-p "\\.")
        (forward-char))
    (delete-horizontal-space t)
    (if (save-excursion
          (backward-char)
          (not (looking-at-p "\\.")))
        (insert "."))
    (insert (mapconcat 'identity (split-string words) "_"))
    (dss/py-fix-last-utterance)
    (delete-horizontal-space t)))

(defun dss/py-decorate-function (&optional decorator-name)
  (interactive)
  (if (not (looking-at "@"))
      (progn
        (py-beginning-of-def-or-class)
        (while (not (save-excursion
                      (forward-line -2)
                      (beginning-of-line-text)
                      (looking-at-p "$")))
          (save-excursion
            (forward-line -1)
            (end-of-line)
            (open-line 1)))
        (forward-line -1)
        (py-indent-line)
        (beginning-of-line-text)
        (if (not (looking-at "@"))
            (progn
              (insert "@")
              (if decorator-name
                  (insert decorator-name)))))))

(defun dss/py-make-classmethod ()
  (interactive)
  (dss/py-decorate-function "classmethod"))

(defun dss/py-comment-line-p ()
  "Return non-nil iff current line has only a comment.
This is python-comment-line-p from Dave Love's python.el"
  (save-excursion
    (end-of-line)
    (when (eq 'comment (syntax-ppss-context (syntax-ppss)))
      (back-to-indentation)
      (looking-at (rx (or (syntax comment-start) line-end))))))

;; setup pymacs
(autoload 'pymacs-apply "pymacs")
(autoload 'pymacs-call "pymacs")
(autoload 'pymacs-eval "pymacs" nil t)
(autoload 'pymacs-exec "pymacs" nil t)
(autoload 'pymacs-load "pymacs" nil t)

(defvar dss-ropemacs-loaded nil)
(defun dss/ropemacs-init ()
  (interactive)
  (unless dss-ropemacs-loaded
    (if (not (boundp 'ropemacs-global-prefix))
        (setq ropemacs-global-prefix nil))
    (pymacs-load "ropemacs" "rope-")
    (setq ropemacs-enable-autoimport nil)
    (define-key ropemacs-local-keymap (kbd "M-/") nil)
    (setq dss-ropemacs-loaded t)))


(defun dss/py-next-line ()
  (interactive)
  (end-of-line)
  (py-newline-and-indent))

(defun dss/py-insert-self ()
  "Insert self. at the beginning of the current expression."
  (interactive)
  (cond ((save-excursion
           (search-backward-regexp "[ \n\t,(-]\\|^")
           (looking-at "[A-Za-z_]+"))
         (save-excursion
           (search-backward-regexp "[ \n\t,(-]\\|^")
           (if (not (looking-at "^"))
               (forward-char))
           (insert "self.")))
        ((looking-at " *$")
         (insert "self"))
        (t (insert "self"))))

(defun dss/python-mode-hook ()
  (dss/install-whitespace-cleanup-hook)
  (turn-on-auto-fill)
  (which-function-mode t)
  (set 'beginning-of-defun-function 'py-beginning-of-def-or-class)
  (setq outline-regexp "def\\|class ")

  (setq py-python-command-args '("-colors" "Linux"))
  (if (and (string-match "\\.py$" (buffer-name))
           ; and isn't a py-shell tmp buffer:
           (not (string-match "python-" (buffer-name))))
      (progn
        ;; (unless dss/ecb-loaded
        ;;   (dss/load-ecb)
        ;;   (smex-update))
        (dss/load-lineker-mode)
        (flymake-mode t)
        (linum-mode t)
        (dss/ropemacs-init)
        (ropemacs-mode t)
        (dss/load-rope-completion)))

  ;; custom keybindings
  (mapc (lambda (char)
            (progn
              (define-key py-mode-map char 'dss/electric-pair)
              (define-key py-shell-map char 'dss/electric-pair)
              ))
          '("\"" "\'" "(" "[" "{"))

  (define-key py-mode-map (kbd "C-p") 'dss/py-insert-self)

  (define-key py-mode-map (kbd "M-RET") 'dss/py-next-line)
  (define-key py-mode-map (kbd "C-M-@") 'rope-code-assist)
  (define-key py-mode-map (kbd "M-/") 'dss/hippie-expand)
  (define-key py-mode-map (kbd "M-.") 'rope-goto-definition)

  (define-key py-shell-map (kbd "C-M-@") 'dss/ido-ipython-complete)

  (define-key py-shell-map "\C-e" (lambda ()
                                    (interactive)
                                    (goto-char (point-max))))
  (define-key py-shell-map (quote [up]) 'comint-previous-matching-input-from-input)
  (define-key py-shell-map (quote [down]) 'comint-next-matching-input-from-input)

  (local-set-key "\C-ch" 'pylookup-lookup))

(add-hook 'python-mode-hook 'dss/python-mode-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; python-mode helpers

;; ipython related
(require 'ipython)
(setq ipython-command "emacs_ipython") ; which is a shell script that handles all the virtualenv setup, etc

(defun dss/start-ipy-complete ()
  (interactive)
  (setq ac-sources '(ac-source-dss-ipy-dot ac-source-dss-ipy ac-source-filename)))

(add-hook 'ipython-shell-hook 'dss/start-ipy-complete)
(add-hook 'py-shell-hook 'dss/start-ipy-complete)

(add-hook 'ipython-shell-hook '(lambda () (linum-mode -1)))
(add-hook 'py-shell-hook '(lambda () (linum-mode -1)))

;;

(autoload 'rst "rst")
(add-to-list 'auto-mode-alist '("\\.rst$" . rst-mode))
;;
(autoload 'doctest-mode "doctest-mode" "Editing mode for Python Doctest examples." t)
(autoload 'doctest-register-mmm-classes "doctest-mode")
(add-to-list 'auto-mode-alist '("\\.doctest$" . doctest-mode))
(doctest-register-mmm-classes t t)
; # @@TR: eldoc

;; cheetah .tmpl files
(autoload 'cheetah-mode "cheetah-mode")
(add-to-list 'auto-mode-alist '("\\.tmpl$" . cheetah-mode))

;; `Cython' mode.
(autoload 'cython-mode "cython-mode")
(add-to-list 'auto-mode-alist '("\\.pyx$" . cython-mode))
(add-to-list 'auto-mode-alist '("\\.pxd$" . cython-mode))


;; pylookup, to look though online Python docs
;; (git clone git://github.com/tsgates/pylookup.git)
(setq dss-pylookup-dir (concat dss-vendor-dir "pylookup/"))
(setq pylookup-program (concat dss-pylookup-dir "pylookup.py"))
(setq pylookup-db-file (concat dss-pylookup-dir "pylookup.db"))

(load-file (concat dss-pylookup-dir "pylookup.el"))
(eval-when-compile (require 'pylookup))
(autoload 'pylookup-lookup "pylookup"
  "Lookup SEARCH-TERM in the Python HTML indexes." t)
(autoload 'pylookup-update "pylookup"
  "Run pylookup-update and create the database at `pylookup-db-file'." t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'dss-python)
