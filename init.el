(defun ds/tangle-init ()
  "If the current buffer is 'init.org' the code-blocks are
tangled, and the tangled file is compiled."
  (when (equal (buffer-file-name)
               (expand-file-name (concat user-emacs-directory "init.org")))
    ;; Avoid running hooks when tangling.
    (let ((prog-mode-hook nil))
      (org-babel-tangle)
                                        ;(byte-compile-file (concat user-emacs-directory "init.el"))
      )))

(add-hook 'after-save-hook 'ds/tangle-init)

(setq inhibit-startup-message t)

(require 'package)
(setq package-enable-at-startup nil)
(setq package-archives
      '(("melpa"        . "http://melpa.org/packages/")
        ("melpa-stable" . "http://stable.melpa.org/packages/")
        ("gnu"          . "http://elpa.gnu.org/packages/")
        ("org"          . "http://orgmode.org/elpa/"))
      package-archive-priorities
      '(("org"          . 20)
        ("melpa-stable" . 15)
        ("gnu"          . 10)
        ("melpa"        . 0)))

(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
;; use-package should have these loaded
(require 'diminish)
(use-package delight
  :ensure t)
(require 'bind-key)

(setq-default create-lockfiles nil)

(defvar ds/backup-directory
  (expand-file-name "tmp/backups" user-emacs-directory)
  "Where backups go.")
(defvar ds/autosave-directory
  (expand-file-name "tmp/autosave" user-emacs-directory)
  "Where autosaves go.")
(make-directory ds/backup-directory t)
(make-directory ds/autosave-directory  t)
(setq backup-by-copying t
      backup-directory-alist `((".*" .  ,ds/backup-directory))
      auto-save-file-name-transforms `((".*"  ,ds/autosave-directory t))
      auto-save-list-file-prefix  ds/autosave-directory
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)

(menu-bar-mode -1)
(tool-bar-mode -1)
(if (boundp 'scroll-bar-mode)
    (scroll-bar-mode -1))

(add-to-list 'default-frame-alist '(font . "Monospace-12"))

(defvar custom-file-location
  (expand-file-name "custom.el" user-emacs-directory)
  "File for customizations via \\[customize].")

(setq custom-file custom-file-location)
(if (file-readable-p custom-file-location)
    (progn
      (load custom-file)))

(defmacro ds/popup-thing-display-settings (BUFFER-NAME SIDE &optional SLOT SIZE)
  `(add-to-list 'display-buffer-alist
                '(,(concat "\\`" (regexp-quote BUFFER-NAME) "\\'")
                  (display-buffer-reuse-window
                   display-buffer-in-side-window)
                  (side            . ,SIDE)
                  ,(if SLOT `(slot            . ,SLOT))
                  (reusable-frames)
                  (inhibit-switch-frame . t)
                  ,(if SIZE
                       (if (or (equal SIDE 'top)
                               (equal SIDE 'bottom))
                           `(window-height . ,SIZE)
                         `(window-width   . ,(if (< SIZE 1) SIZE
                                               `(lambda (win)
                                                  (if (or (< (window-width win) ,SIZE)
                                                          (not (or (window-in-direction 'above win t)
                                                                   (window-in-direction 'below win t))))
                                                      (ds/set-window-column-width ,SIZE win))))))))))

(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq-default tab-stop-list (number-sequence 4 120 4))

(electric-indent-mode 1)

;; ignore for python
(defun electric-indent-ignore-python (char)
  "Ignore Electric Indent for Python, CHAR is ignored."
  (if (or
       (equal major-mode 'python-mode)
       (equal major-mode 'markdown-mode)
       (equal major-mode 'makefile-gmake-mode)
       (equal major-mode 'picture-mode)
       (equal major-mode 'gl-conf-mode)
       (equal major-mode 'nginx-mode)
       (equal major-mode 'yaml-mode)
       (equal major-mode 'org-mode)
       (equal major-mode 'org-journal-mode))
      `no-indent'
    t))
(add-to-list 'electric-indent-functions 'electric-indent-ignore-python)

(defun set-newline-and-indent ()
  "Map RET key to `newline-and-indent'."
  (local-set-key (kbd "RET") 'newline-and-indent))
(add-hook 'python-mode-hook 'set-newline-and-indent)
(add-hook 'markdown-mode-hook 'set-newline-and-indent)

(defvar newline-and-indent t "Make line openings use auto indent.")

(defun open-next-line (count)
        "Open COUNT lines after the current one.

See also `newline-and-indent'."
        (interactive "p")
        (end-of-line)
        (open-line count)
        (forward-line count)
        (when newline-and-indent
          (indent-according-to-mode)))
;; Behave like vi's O command
(defun open-previous-line (count)
        "Open COUNT new line before the current one.

See also `newline-and-indent'."
        (interactive "p")
        (beginning-of-line)
        (open-line count)
        (when newline-and-indent
          (indent-according-to-mode)))

(global-set-key (kbd "C-o") 'open-next-line)
(global-set-key (kbd "M-o") 'open-previous-line)

(show-paren-mode)

(put 'narrow-to-region 'disabled nil)

(defvar erc-hide-list '("JOIN" "PART" "QUIT"))

(ds/popup-thing-display-settings "*compilation*" right 2 104)

(setq compilation-finish-functions
      '((lambda (buf str)
          (message "compilation %s" str)
          (if (eq 0 (string-match-p "^finished$" str))
              (let ((project-root (if (projectile-project-p) (projectile-project-root) nil)))
                (run-at-time
                 2 nil 'delete-windows-on
                 (get-buffer-create "*compilation*"))
                (if project-root
                  (run-at-time
                   2.01 nil 'projectile-vc project-root)))))))

(setq compilation-scroll-output t)

(use-package compile
  :config
  (define-key compilation-mode-map (kbd "q") #'delete-window))

(use-package ediff
  :config
  (setq ediff-window-setup-function #'ediff-setup-windows-plain))

(use-package eshell
  :config
  (setenv "PAGER" "cat")

  ;; add "pin" to the list of words for detecting password entry from eshell
  (push "pin" password-word-equivalents)
  (setq eshell-password-prompt-regexp (format "\\(%s\\).*:\\s *\\'" (regexp-opt password-word-equivalents)))

  (setq eshell-scroll-to-bottom-on-input 'all
        eshell-error-if-no-glob t
        eshell-hist-ignoredups t
        eshell-save-history-on-exit t
        eshell-prefer-lisp-functions nil
        eshell-history-size 2048
        eshell-destroy-buffer-when-process-dies t)

  (add-hook 'eshell-mode-hook
            (lambda ()
              (defvar eshell-visual-commands '()
                "Commands in shell that need a \"real\" terminal")
              (add-to-list 'eshell-visual-commands "ssh")
              (add-to-list 'eshell-visual-commands "tail")
              (add-to-list 'eshell-visual-commands "top")
              (add-to-list 'eshell-visual-commands "htop")
              (setq eshell-path-env (getenv "PATH"))
              (zenburn-with-color-variables
                (set-face-attribute 'eshell-prompt-face nil :foreground zenburn-fg :weight 'normal))))

  ;; share history after every command
  (setq eshell-save-history-on-exit nil)

  (defun ds/eshell-append-history ()
    "Call `eshell-write-history' with the `append' parameter set to `t'."
    (when eshell-history-ring
      (let ((newest-cmd-ring (make-ring 1)))
        (ring-insert newest-cmd-ring (car (ring-elements eshell-history-ring)))
        (let ((eshell-history-ring newest-cmd-ring))
          (eshell-write-history eshell-history-file-name t)))))

  (add-hook 'eshell-pre-command-hook #'ds/eshell-append-history))

(use-package esh-autosuggest
  :ensure t
  :config
  (defun ds/esh-autosuggest-setup ()
    (make-variable-buffer-local 'company-require-match)
    (set-variable 'company-require-match nil)
    (face-remap-add-relative 'company-preview-common 'ds/esh-autosuggest-face))

  (add-hook 'eshell-mode-hook #'esh-autosuggest-mode)
  (add-hook 'eshell-mode-hook #'ds/esh-autosuggest-setup))

(use-package pcmpl-args
  :ensure t
  :config

  ;; ============================================================
  ;;
  ;; pacman completion
  ;;
  ;; ============================================================
  (defvar pcomplete-pacman-installed-packages
    (split-string (shell-command-to-string "pacman -Qq"))
    "p-completion candidates for `pacman' regarding installed packages")

  (defvar pcomplete-pacman-web-packages
    (split-string (shell-command-to-string "pacman -Slq"))
    "p-completion candidates for `pacman' regarding packages on the web")

  (defun pcomplete/pacman ()
    "Completion rule for the `pacman' command."
    (pcomplete-opt "DFQRSUilos")
    (cond ((pcomplete-test "-[DRQ][a-z]*")
           (pcomplete-here pcomplete-pacman-installed-packages))
          ((pcomplete-test "-[FS][a-z]*")
           (pcomplete-here pcomplete-pacman-web-packages))
          (t (pcomplete-here (pcomplete-entries)))))

  ;; ============================================================
  ;;
  ;; pacaur completion
  ;;
  ;; ============================================================
  (defvar pcomplete-pacaur-installed-packages
    (split-string (shell-command-to-string "pacaur -Qq"))
    "p-completion candidates for `pacaur' regarding installed packages")

  (defvar pcomplete-pacaur-web-packages
    (split-string (shell-command-to-string "pacaur -Slq"))
    "p-completion candidates for `pacaur' regarding packages on the web")

  (defun pcomplete/pacaur ()
    "Completion rule for the `pacaur' command."
    (pcomplete-opt "DFQRSUilos")
    (cond ((pcomplete-test "-[DRQ][a-z]*")
           (pcomplete-here pcomplete-pacaur-installed-packages))
          ((pcomplete-test "-[FS][a-z]*")
           (let ((search (pcomplete-arg)))
             (message search)
             (if (< (length search) 3)
                 (pcomplete-here pcomplete-pacaur-web-packages)
               (pcomplete-here (append (split-string
                                        (shell-command-to-string (concat "pacaur -sq " search)))
                                       pcomplete-pacaur-web-packages)))))
          (t (pcomplete-here (pcomplete-entries)))))

  ;; ============================================================
  ;;
  ;; systemctl completion
  ;;
  ;; ============================================================
  (defcustom pcomplete-systemctl-commands
    '("disable" "enable" "status" "start" "restart" "stop" "daemon-reload")
    "p-completion candidates for `systemctl' main commands"
    :type '(repeat (string :tag "systemctl command"))
    :group 'pcomplete)

  (defvar pcomplete-systemd-units
    (split-string
     (shell-command-to-string
      "(systemctl list-units --all --full --no-legend;systemctl list-unit-files --full --no-legend)|while read -r a b; do echo \" $a\";done;"))
    "p-completion candidates for all `systemd' units")

  (defvar pcomplete-systemd-user-units
    (split-string
     (shell-command-to-string
      "(systemctl list-units --user --all --full --no-legend;systemctl list-unit-files --user --full --no-legend)|while read -r a b;do echo \" $a\";done;"))
    "p-completion candidates for all `systemd' user units")

  (defun pcomplete/systemctl ()
    "Completion rules for the `systemctl' command."
    (pcomplete-here (append pcomplete-systemctl-commands '("--user")))
    (cond ((pcomplete-test "--user")
           (pcomplete-here pcomplete-systemctl-commands)
           (pcomplete-here pcomplete-systemd-user-units))
          ((pcomplete-test "daemon-reload")
           (pcomplete-here))
          (t (pcomplete-here pcomplete-systemd-units)))))

(use-package dash
  :ensure t
  :config
  (use-package s
    :ensure t
    :config
    (use-package eshell
      :commands (eshell/pwd)
      :init

      (defvar ds/eshell-sep " | "
        "Separator between esh-sections")

      (defvar ds/eshell-section-delim " "
        "Separator between an esh-section icon and form")

      (defvar ds/eshell-header "\n "
        "Eshell prompt header")

      (setq eshell-prompt-regexp "^ [$#] ")

      (defmacro ds/with-face (STR &rest PROPS)
        "Return STR propertized with PROPS."
        `(propertize ,STR 'face (list ,@PROPS)))

      (defmacro ds/eshell-section (NAME ICON FORM &rest PROPS)
        "Build eshell section NAME with ICON prepended to evaled FORM with PROPS."
        `(defvar ,NAME
           (lambda () (when ,FORM
                        (let ((result (concat ,ICON (if (> (length ,ICON) 0) ds/eshell-section-delim "") ,FORM)))
                          (if ,@PROPS
                              (ds/with-face result ,@PROPS)
                            result))))
           "Eshell prompt section - ,NAME"))


      (defun ds/split-directory-prompt (directory)
        (if (string-match-p ".*/.*" directory)
            (list (file-name-directory directory) (file-name-base directory))
          (list "" directory)))

      (defun ds/pwd-shorten-dirs (pwd)
        "Shorten all directory names in PWD except the last two."
        (let ((p-lst (split-string pwd "/")))
          (if (> (length p-lst) 2)
              (concat
               (mapconcat (lambda (elm) (if (zerop (length elm)) ""
                                          (substring elm 0 1)))
                          (butlast p-lst 2)
                          "/")
               "/"
               (mapconcat (lambda (elm) elm)
                          (last p-lst 2)
                          "/"))
            pwd)))  ;; Otherwise, we just return the PWD

      (ds/eshell-section esh-dir
                         (ds/with-face "" (zenburn-with-color-variables
                                             `(:foreground ,zenburn-fg-1 :weight bold)))
                         (let* ((dirparts (ds/split-directory-prompt (ds/pwd-shorten-dirs (abbreviate-file-name (eshell/pwd)))))
                                (parent (car dirparts))
                                (dirname (cadr dirparts)))
                           (concat (ds/with-face parent (zenburn-with-color-variables
                                                          `(:foreground ,zenburn-bg+3)))
                                   (ds/with-face dirname (zenburn-with-color-variables
                                                           `(:foreground ,zenburn-fg-1 :weight bold))))))

      (ds/eshell-section esh-git
                         (ds/with-face ""
                                       (zenburn-with-color-variables `(:foreground ,zenburn-orange)))
                         (let* ((unstaged-count (length (magit-unstaged-files)))
                                (staged-count (length (magit-staged-files)))
                                (untracked-count (length (magit-untracked-files)))
                                (unstaged (if (> unstaged-count 0)
                                              (ds/with-face
                                               (concat " (" (number-to-string unstaged-count) ")")
                                               (zenburn-with-color-variables `(:foreground ,zenburn-yellow)))
                                            ""))
                                (staged (if (> staged-count 0)
                                            (ds/with-face
                                             (concat " (" (number-to-string staged-count) ")")
                                             (zenburn-with-color-variables `(:foreground ,zenburn-green)))
                                          ""))
                                (untracked (if (> untracked-count 0)
                                               (ds/with-face
                                                (concat " (" (number-to-string untracked-count) ")")
                                                (zenburn-with-color-variables `(:foreground ,zenburn-red)))
                                             "")))
                           (if (magit-get-current-branch)
                               (concat (ds/with-face (magit-get-current-branch)
                                                     (zenburn-with-color-variables `(:foreground ,zenburn-blue)))
                                       staged unstaged untracked)
                             nil)))

      (ds/eshell-section esh-last-command-status
                         ""
                         (if (eq eshell-last-command-status 0)
                             nil
                           (ds/with-face "" (zenburn-with-color-variables `(:foreground ,zenburn-red+1)))))

      (if (boundp 'set-fontset-font)
          (progn (set-fontset-font t '(#Xf017 . #Xf017) "fontawesome")
                 (set-fontset-font t '(#Xf011 . #Xf011) "fontawesome")
                 (set-fontset-font t '(#Xf026 . #Xf028) "fontawesome")))

      (ds/eshell-section esh-clock
                         ""
                         (format-time-string "%H:%M" (current-time))
                         (zenburn-with-color-variables
                           `(:foreground ,zenburn-green)))

      ;; Choose which eshell-funcs to enable
      (defvar ds/eshell-funcs (list (list esh-dir esh-clock) (list esh-git) (list esh-last-command-status))
        "Eshell prompt sections")

      (defun ds/eshell-acc (acc x)
        "Accumulator for evaluating and concatenating esh-sections."
        (if (and (listp x) (not (functionp x)))
            (concat acc (-reduce-from 'ds/eshell-acc "" x) "\n ")
          (--if-let (funcall x)
              (if (s-blank? acc)
                  it
                (concat acc
                        (if (string= "\n" (substring acc (- (length acc) 1) (length acc)))
                            " "
                          ds/eshell-sep)
                        it))
            acc)))

      (defun ds/eshell-prompt-func ()
        "Build `eshell-prompt-function'"
        (concat ds/eshell-header
                (replace-regexp-in-string "\n $" "" (-reduce-from 'ds/eshell-acc "" ds/eshell-funcs))
                "\n"
                (concat " " (if (= (user-uid) 0) "#" "$") " ")))

      ;; Enable the new eshell prompt
      (setq eshell-prompt-function 'ds/eshell-prompt-func)

      )))

(defun ds/ansi-term-handle-close ()
  "Close current term buffer when `exit' from term buffer."
  (when (ignore-errors (get-buffer-process (current-buffer)))
    (set-process-sentinel (get-buffer-process (current-buffer))
                          (lambda (proc change)
                            (when (string-match "\\(finished\\|exited\\)" change)
                              (kill-buffer (process-buffer proc))
                              (if (not (= (length (window-list)) 1))
                                  (delete-window)))))))

(add-hook 'term-mode-hook #'ds/ansi-term-handle-close)

(defun sh-script-extra-font-lock-match-var-in-double-quoted-string (limit)
  "Search for variables in double-quoted strings."
  (let (res)
    (while
        (and (setq res (progn (if (eq (get-byte) ?$) (backward-char))
                              (re-search-forward
                               "[^\\]\\$\\({#?\\)?\\([[:alpha:]_][[:alnum:]_]*\\|[-#?@!]\\|[[:digit:]]+\\)"
                               limit t)))
             (not (eq (nth 3 (syntax-ppss)) ?\")))) res))

(defvar sh-script-extra-font-lock-keywords
  '((sh-script-extra-font-lock-match-var-in-double-quoted-string
     (2 font-lock-variable-name-face prepend))))

(defun sh-script-extra-font-lock-activate ()
  (interactive)
  (font-lock-add-keywords nil sh-script-extra-font-lock-keywords)
  (if (fboundp 'font-lock-flush)
      (font-lock-flush)
    (when font-lock-mode (with-no-warnings (font-lock-fontify-buffer)))))

(add-hook 'sh-mode-hook 'sh-script-extra-font-lock-activate)

(add-to-list 'auto-mode-alist '("PKGBUILD$" . sh-mode))
(add-to-list 'auto-mode-alist '("zshrc$" . sh-mode))
(add-to-list 'auto-mode-alist '("zshenv$" . sh-mode))
(add-to-list 'auto-mode-alist '("zprofile$" . sh-mode))

(add-function :before (symbol-function 'scroll-down-command) #'push-mark)

(setq tramp-ssh-controlmaster-options
                (concat
                  "-o ControlPath=/tmp/ssh-ControlPath-%%r@%%h:%%p "
                  "-o ControlMaster=auto -o ControlPersist=yes"))

(add-hook 'prog-mode-hook #'electric-pair-local-mode)

(defun directory-files-recursive(directory &optional match)
  "Get all files in DIRECTORY recursivley.
There are three optional arguments:
If FULL is non-nil, return absolute file names.  Otherwise return names
 that are relative to the specified directory.
If MATCH is non-nil, mention only file names that match the regexp MATCH.
If NOSORT is non-nil, the list is not sorted--its order is unpredictable.
 Otherwise, the list returned is sorted with `string-lessp'.
 NOSORT is useful if you plan to sort the result yourself."
  (interactive)
  (let (file-list
        (current-dir-list (directory-files-and-attributes directory t))
        (match (if match match "^[^.].*"))) ; ignore hidden files by default
    (while current-dir-list
      (let ((file-name (car (car current-dir-list)))
            (is-dir (equal t (car (cdr (car current-dir-list))))))
        (cond
         ;; if the filename matches the match string
         (is-dir
          ;; make sure it is not a hidden dir
          (if (or
               (equal "." (substring file-name -1))
               (equal "." (substring (file-name-nondirectory file-name) 0 1)))
              ()
            ;; recurse it adding the result to the list
            (setq file-list
                  (append
                   (directory-files-recursive file-name match)
                   file-list))))
         ((string-match match (file-name-nondirectory file-name))
          (setq file-list (cons file-name file-list)))))
      (setq current-dir-list (cdr current-dir-list)))
    file-list))

(defun ds/indent-buffer ()
  "Indent entire buffer using `indent-according-to-mode'."
  (interactive)
  (if (overlayp mmm-current-overlay)
      (ds/indent-mmm-section)
  (save-excursion
    (push-mark (point))
    (push-mark (point-max) nil t)
    (goto-char (point-min))
    (indent-region (region-beginning) (region-end)))))

(defun ds/indent-mmm-section ()
  "Indent entire MMM section using `indent-according-to-mode'."
  (interactive)
  (save-excursion
    (push-mark (point))
    (push-mark (mmm-back-end mmm-current-overlay) nil t)
    (goto-char (mmm-front-start mmm-current-overlay))
    (indent-region (region-beginning) (region-end))))

(global-set-key (kbd "C-c \\") 'ds/indent-buffer)

(defun set-local-variable (varname value)
  "Make a variable VARNAME local to the buffer if needed, then set to VALUE."
  (interactive "vVariable Name: \nsNew Value: ")
  (let  ((number (string-to-number value)))
    (make-variable-buffer-local varname)
    (if (and (= 0 number) (not (string-equal "0" value)))
        (set-variable varname value)
      (set-variable varname number))))

(defvar ds/serif-preserve-default-list nil
  "A list holding the faces that preserve the default family and height when TOGGLE-SERIF is used.")
(defvar ds/preserve-default-cookies-list nil
  "A list holding the faces that preserve the default family and height when TOGGLE-SERIF is used.")
(defvar ds/default-cookie nil
  "A list holding the faces that preserve the default family and height when TOGGLE-SERIF is used.")

(setq ds/serif-preserve-default-list
      '(;; LaTeX markup
        font-latex-math-face
        font-latex-sedate-face
        font-latex-warning-face
        ;; org markup
        org-latex-and-related
        org-meta-line
        org-verbatim
        org-block-begin-line
        org-block
        org-code
        org-date
        ;; syntax highlighting using font-lock
        font-lock-builtin-face
        font-lock-comment-delimiter-face
        font-lock-comment-face
        font-lock-constant-face
        font-lock-doc-face
        font-lock-function-name-face
        font-lock-keyword-face
        font-lock-negation-char-face
        font-lock-preprocessor-face
        font-lock-regexp-grouping-backslash
        font-lock-regexp-grouping-construct
        font-lock-string-face
        font-lock-type-face
        font-lock-variable-name-face
        font-lock-warning-face))

(require 'face-remap)

(defun ds/toggle-serif ()
  "Change the default face of the current buffer to use a serif family."
  (interactive)
  (when (display-graphic-p)  ;; this is only for graphical emacs
    ;; the serif font familiy and height, save the default attributes
    (let ((serif-fam "Ubuntu")
          (serif-height 105)
          (default-fam (face-attribute 'default :family))
          (default-height (face-attribute 'default :height)))
      (if (not (bound-and-true-p ds/default-cookie))
          (progn (make-local-variable 'ds/default-cookie)
                 (make-local-variable 'ds/preserve-default-cookies-list)
                 (setq ds/preserve-default-cookies-list nil)
                 ;; remap default face to serif
                 (setq ds/default-cookie
                       (face-remap-add-relative
                        'default :family serif-fam :height serif-height))
                 ;; keep previously defined monospace fonts the same
                 (dolist (face ds/serif-preserve-default-list)
                   (add-to-list 'ds/preserve-default-cookies-list
                                (face-remap-add-relative
                                 face :family default-fam :height default-height)))
                 (message "Turned on serif writing font."))
        ;; undo changes
        (progn (face-remap-remove-relative ds/default-cookie)
               (dolist (cookie ds/preserve-default-cookies-list)
                 (face-remap-remove-relative cookie))
               (setq ds/default-cookie nil)
               (setq ds/preserve-default-cookies-list nil)
               (message "Restored default fonts."))))))

(defun ds/find-eslint-executable ()
  (let* ((root (locate-dominating-file
                (or (buffer-file-name) default-directory)
                "node_modules"))
         (eslint-local (and root
                            (expand-file-name "node_modules/eslint/bin/eslint.js"
                                              root)))
         (eslint-system (executable-find "eslint")))
    (if (and (stringp eslint-local)
             (file-executable-p eslint-local))
        eslint-local
      eslint-system)))

(defun ds/set-window-pixel-width (pixel-width &optional window)
  "Set the WINDOW to PIXEL-WIDTH pixels wide"
  (interactive "nNew Pixel Width: ")
  (let* ((win (or window (selected-window)))
         (current-width (window-pixel-width win))
         (wanted-delta (- pixel-width current-width))
         (delta (window-resizable win wanted-delta t nil t)))
    (window-resize win delta t nil t)))

(defun ds/set-window-column-width (column-width &optional window)
  "Set the WINDOW to COLUMN-WIDTH columns wide"
  (interactive "nNew Column Width: ")
  (let* ((win (or window (selected-window)))
         (current-width (window-width win))
         (wanted-delta (- column-width current-width))
         (delta (window-resizable win wanted-delta t)))
    (message "%s %d -> %d (%d)" win current-width column-width delta)
    (window-resize win delta t)))

(defun ds/set-window-pixel-height (pixel-height &optional window)
  "Set the WINDOW to PIXEL-HEIGHT pixels wide"
  (interactive "nNew Pixel Height: ")
  (let* ((win (or window (selected-window)))
         (current-height (window-pixel-height win))
         (wanted-delta (- pixel-height current-height))
         (delta (window-resizable win wanted-delta nil nil t)))
    (window-resize win delta nil nil t)))

(defun ds/set-window-column-height (column-height &optional window)
  "Set the WINDOW to COLUMN-HEIGHT columns wide"
  (interactive "nNew Column Height: ")
  (let* ((win (or window (selected-window)))
         (current-height (window-height win))
         (wanted-delta (- column-height current-height))
         (delta (window-resizable win wanted-delta)))
    (message "%s %d -> %d (%d)" win current-height column-height delta)
    (window-resize win delta)))

(defun ds/set-window-ratio (&optional win width height horizontal)
  "Set WIN size ratio in pixels based on WIDTH and HEIGHT, optionally resize HORIZONTAL."
  (interactive "i\nnWidth: \nnHeight: \nSHorizontal: ")
  (let* ((padding 19)
         (win (or win (selected-window)))
         (w (float (or width 16)))
         (h (float (or height 9)))
         (ratio (/ w h))
         (original-size (if horizontal
                            (window-width win t)
                          (- (window-pixel-height win) padding)))
         (reference-size (if horizontal
                             (- (window-pixel-height win) padding)
                           (window-width win t)))
         (new-size (if horizontal
                       (truncate (* reference-size ratio))
                     (truncate (* reference-size (/ 1 ratio)))))
         (delta (- new-size original-size)))
    (message "%s %f reference: %d current: %d -> new: %d (delta: %d)" horizontal ratio reference-size original-size new-size delta)
    (if horizontal
        (ds/set-window-pixel-width new-size win)
      (ds/set-window-pixel-height (+ new-size padding) win))))

(defun ds/clear-minibuffer (&rest _)
  (message nil))

(defun ds/blockchain-sync-status ()
  (interactive)
  (with-temp-buffer
    (call-process "bitcoin-cli" nil t t "getblockchaininfo")
    (let* ((json (json-read-from-string (buffer-string)))
           (blocks (alist-get 'blocks json))
           (total-blocks (alist-get 'headers json))
           (completion (truncate (* 100 (/ (float blocks) (float total-blocks))))))
      (message "%s%% completed (%s/%s)" completion blocks total-blocks))))

(defun align-repeat (start end regexp)
    "Repeat alignment with respect to 
     the given regular expression."
    (interactive "r\nsAlign regexp: ")
    (align-regexp start end 
        (concat "\\(\\s-*\\)" regexp) 1 1 t))

(defun ds/toggle-camelcase-underscores ()
  "Toggle between camelcase and underscore notation for the symbol at point."
  (interactive)
  (save-excursion
    (let* ((bounds (bounds-of-thing-at-point 'symbol))
           (start (car bounds))
           (end (cdr bounds))
           (currently-using-underscores-p (progn (goto-char start)
                                                 (re-search-forward "_" end t))))
      (if currently-using-underscores-p
          (progn
            (upcase-initials-region start end)
            (replace-string "_" "" nil start end)
            (downcase-region start (1+ start)))
        (replace-regexp "\\([A-Z]\\)" "_\\1" nil (1+ start) end)
        (downcase-region start (cdr (bounds-of-thing-at-point 'symbol)))))))

(global-set-key (kbd "C-c _") 'ds/toggle-camelcase-underscores)

(defcustom fence-edit-lang-modes
  '(("cl" . lisp-interaction-mode))
  "A mapping from markdown language symbols to the modes they should be edited in."
  :group 'fence-edit
  :type '(repeat
          (cons
           (string "Language name")
           (symbol "Major mode"))))

(defcustom fence-edit-default-mode
  'text-mode
  "The default mode to use if a language-appropriate mode cannot be determined."
  :group 'fence-edit
  :type '(symbol))

(defcustom fence-edit-blocks
  '(("^[[:blank:]]*\\(?:```\\|~~~\\)[ ]?\\([^[:space:]]+\\|{[^}]*}\\)?\\(?:[[:space:]]*?\\)$"
     "^[[:blank:]]*\\(?:```\\|~~~\\)\\s *?$"
     1)
    ("^<template>$" "^</template>$" web)
    ("^<script>$" "^</script>$" js)
    ("^<style[ ]?\\(scoped\\)?>" "^</style>$" css)
    ("^<style lang=\"stylus\"[ ]?\\(scoped\\)?>" "^</style>$" )
    ("^<style lang=\"scss\"[ ]?\\(scoped\\)?>" "^</style>$" scss)
    ("^<style lang=\"sass\"[ ]?\\(scoped\\)?>" "^</style>$" sass))
  "Alist of regexps matching editable blocks.

Each element takes the form
\(START-REGEXP END-REGEXP LANG-RULE)

Where START- and END-REGEXP are patterns matching the start and end of
the block, respectively.

If LANG-RULE is a symbol, that symbol is assumed to be a language
name.

If LANG-RULE is an integer, it is assumed to be the number of a
capture group to pass to `match-string' to get the language (a capture
group within the START-REGEXP).

If the language value with `-mode' appended to it does not resolve to
a bound function, it will be used to look up a mode in
`fence-edit-lang-modes'.  If the symbol doesn't match a key in
that list, the `fence-edit-default-mode' will be used."
  :group 'fence-edit
  :type '(repeat
          (list
           (regexp "Start regexp")
           (regexp "End regexp")
           (choice (integer "Capture group number")
                   (symbol "Language name")))))

(defconst fence-edit-window-layout 48529384
  "Register in which to save the window layout.

Registers are chars, so this is set to an int that is not likely to be
used by anything else.")

(defvar-local fence-edit-previous-mode nil
  "Mode set before narrowing, restored upon widening.")

(defvar-local fence-edit-overlay nil
  "An overlay used to indicate the original text being edited.")

(defvar-local fence-edit-mark-beg nil
  "A marker at the beginning of the edited text block.

Used to replace the text upon completion of editing.")

(defvar-local fence-edit-mark-end nil
  "A marker at the end of the edited text block.

Used to replace the text upon completion of editing.")

(defvar-local fence-edit-block-indent nil
  "The indentation of the first line.

Used to strip and replace the indentation upon beginning/completion of editing.")

(defvar fence-edit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'fence-edit-exit)
    (define-key map (kbd "C-c '")   'fence-edit-exit)
    (define-key map (kbd "C-c C-k") 'fence-edit-abort)
    (define-key map (kbd "C-x C-s") 'fence-edit-save)
    map)
  "The keymap used in ‘fence-edit-mode’.")

(define-minor-mode fence-edit-mode
  "A minor mode used when editing a fence-edit block."
  nil "Fence-Edit"
  fence-edit-mode-map)

(defvar fence-edit-mode-hook nil
  "Hook run when fence-edit has set the block's language mode.

You may want to use this to disable language mode configurations that
don't work well in the snippet view.")

(defun fence-edit-mode-configure ()
  "Configure the fence-edit edit buffer."
  (add-hook 'kill-buffer-hook
            #'(lambda () (delete-overlay fence-edit-overlay)) nil 'local))

(add-hook 'fence-edit-mode-hook 'fence-edit-mode-configure)

(defsubst fence-edit-set-local (var value)
  "Make VAR local in current buffer and set it to VALUE."
  (set (make-local-variable var) value))

(defun fence-edit--make-edit-buffer-name (base-buffer-name lang)
  "Make an edit buffer name from BASE-BUFFER-NAME and LANG."
  (concat "*Narrowed Edit " base-buffer-name "[" lang "]*"))

(defun fence-edit--next-line-beginning-position-at-pos (pos)
  "Return the position of the beginning of the line after the line at POS.

Used to find the position at which the code to edit begins, covering
for a common case where the block start regexp doesn't match the
ending line break and that break gets sucked into the block of code to
edit."
  (interactive)
  (save-excursion
    (goto-char pos)
    (forward-line)
    (line-beginning-position)))

(defun fence-edit--get-block-around-point ()
  "Return metadata about block surrounding point.

Return nil if no block is found."
  (save-excursion
    (beginning-of-line)
    (let ((pos (point))
          (blocks fence-edit-blocks)
          block re-start re-end lang-id start end lang)
      (catch 'exit
        (while (setq block (pop blocks))
          (save-excursion
            (setq re-start (car block)
                  re-end (nth 1 block)
                  lang-id (nth 2 block))
            (if (or (looking-at re-start)
                    (re-search-backward re-start nil t))
                (progn
                  (setq start (fence-edit--next-line-beginning-position-at-pos (match-end 0))
                        lang (if (integerp lang-id)
                                 (match-string lang-id)
                               (symbol-name lang-id)))
                  (if (and (and (goto-char (match-end 0))
                                (re-search-forward re-end nil t))
                           (>= (match-beginning 0) pos))
                      (throw 'exit `(,start ,(match-beginning 0) ,lang)))))))))))

(defun fence-edit--get-mode-for-lang (lang)
  "Try to get a mode function from language name LANG.

The assumption is that language `LANG' has a mode `LANG-mode'."
  (let ((mode-name (intern (concat lang "-mode"))))
    (if (fboundp mode-name)
        mode-name
      (if (assoc lang fence-edit-lang-modes)
          (cdr (assoc lang fence-edit-lang-modes))
        fence-edit-default-mode))))

(defun fence-edit-code-at-point ()
  "Look for a code block at point and, if found, edit it."
  (interactive)
  (let* ((block (fence-edit--get-block-around-point))
         (pos (point))
         (beg (make-marker))
         (end (copy-marker (make-marker) t))
         (block-indent "")
         edit-point lang code mode ovl edit-buffer vars first-line)
    (if block
        (progn
          (setq beg (move-marker beg (car block))
                end (move-marker end (nth 1 block))
                edit-point (1+ (- pos beg))
                lang (nth 2 block)
                code (buffer-substring-no-properties beg end)
                mode (fence-edit--get-mode-for-lang lang)
                ovl (make-overlay beg end)
                edit-buffer (generate-new-buffer
                             (fence-edit--make-edit-buffer-name (buffer-name) lang)))
          (window-configuration-to-register fence-edit-window-layout)
          (if (string-match-p (rx "\n" string-end) code)
              (setq code (replace-regexp-in-string (rx "\n" string-end) "" code)))
          (setq first-line (car (split-string code "\n")))
          (string-match "^[[:blank:]]*" first-line)
          (setq block-indent (match-string 0 first-line))
          (setq code (replace-regexp-in-string (concat "^" block-indent) "" code))
          (overlay-put ovl 'edit-buffer edit-buffer)
          (overlay-put ovl 'face 'secondary-selection)
          (overlay-put ovl :read-only "Please don't.")
          (switch-to-buffer-other-window edit-buffer t)
          (insert code)
          (remove-text-properties (point-min) (point-max)
                                  '(display nil invisible nil intangible nil))
          (condition-case e
              (funcall mode)
            (error
             (message "Language mode `%s' fails with: %S" mode (nth 1 e))))
          (fence-edit-mode)
          (fence-edit-set-local 'fence-edit-editor t)
          (fence-edit-set-local 'fence-edit-mark-beg beg)
          (fence-edit-set-local 'fence-edit-mark-end end)
          (fence-edit-set-local 'fence-edit-block-indent block-indent)
          (fence-edit-set-local 'fence-edit-overlay ovl)
          (fence-edit-set-local 'header-line-format "Press C-c ' (C-c apostrophe) to save, C-c C-k to abort.")
          (goto-char edit-point)
          (set-buffer-modified-p nil)))))

(defun fence-edit--guard-edit-buffer ()
  "Throw an error if current buffer doesn't look like an edit buffer."
  (unless (bound-and-true-p fence-edit-editor)
    (error "This is not a fence-edit editor; something is wrong")))

(defun fence-edit--abandon-edit-buffer (dest-buffer)
  "Trash the edit buffer and switch to DEST-BUFFER.

The edit buffer is expected to be the current buffer."
  (interactive "P")
  (fence-edit--guard-edit-buffer)
  (let ((buffer (current-buffer)))
    (switch-to-buffer-other-window dest-buffer)
    (jump-to-register fence-edit-window-layout)
    (with-current-buffer buffer
      (set-buffer-modified-p nil))
    (kill-buffer buffer)))

(defun fence-edit-save () 
  "Save the original buffer with the new text."
  (interactive)
  (fence-edit--guard-edit-buffer)
  (let ((beg fence-edit-mark-beg))
    (fence-edit-replace)
    (set-buffer-modified-p nil)
    (with-current-buffer (marker-buffer beg)
      (save-buffer))))

(defun fence-edit-exit ()
  "Conclude editing, replacing the original text."
  (interactive)
  (fence-edit--guard-edit-buffer)
  (let ((code (buffer-string))
        (edit-point (point))
        (beg fence-edit-mark-beg)
        (end fence-edit-mark-end))
    (fence-edit-replace)
    (fence-edit--abandon-edit-buffer (marker-buffer beg))
    (goto-char (1- (+ beg edit-point)))
    (set-marker beg nil)
    (set-marker end nil)))

(defun fence-edit-replace ()
  "Continue editing, replacing the original text."
  (interactive)
  (fence-edit--guard-edit-buffer)
  (let ((buffer (current-buffer))
        (code (buffer-string))
        (beg fence-edit-mark-beg)
        (end fence-edit-mark-end)
        (block-indent fence-edit-block-indent)
        (edit-point (point))
        (ovl fence-edit-overlay))
    (if (not (string-match-p (rx "\n" string-end) code))
        (setq code (concat code "\n")))
    (setq code (replace-regexp-in-string "\n" (concat "\n" block-indent) code))
    (setq code (concat block-indent code))
    (setq code (replace-regexp-in-string (concat "\n" block-indent "$") "\n" code))
    (with-current-buffer (marker-buffer beg)
      (goto-char beg)
      (undo-boundary)
      (delete-region beg end)
      (insert code))))

(defun fence-edit-abort ()
  "Conclude editing, discarding the edited text."
  (interactive)
  (fence-edit--guard-edit-buffer)
  (let ((dest-buffer (marker-buffer fence-edit-mark-beg)))
    (fence-edit--abandon-edit-buffer dest-buffer)))


(global-set-key (kbd "C-c '") 'fence-edit-code-at-point)

(defvar chordpro-font-lock-defaults
  '((("\\(\\[[^]]*\\]\\)" . font-lock-string-face)
     ("^\\(#.*\\)" . font-lock-comment-face)
     ("\\({subtitle[^}]*}\\)" . font-lock-type-face)
     ("\\({title[^}]*}\\)" . font-lock-keyword-face)
     ("\\({[^}]*}\\)" . font-lock-variable-name-face))))


(define-derived-mode chordpro-mode text-mode "Chordpro"
  "Major mode for editing Chordpro files.
Special commands:
\\{chordpro-mode-map}"
  (setq font-lock-defaults chordpro-font-lock-defaults)
  (auto-fill-mode -1))

(add-to-list 'auto-mode-alist '("\\.pro$" . chordpro-mode))
(add-to-list 'auto-mode-alist '("\\.chopro$" . chordpro-mode))
(add-to-list 'auto-mode-alist '("\\.chordpro$" . chordpro-mode))

(use-package zenburn-theme
  :ensure t
  :demand t
  :init
  (defvar zenburn-colors-alist
    '(("zenburn-fg+1"     . "#FFFFEF")
      ("zenburn-fg"       . "#DCDCCC")
      ("zenburn-fg-05"    . "#989888")
      ("zenburn-fg-1"     . "#656555")
      ("zenburn-bg-2"     . "#000000")
      ("zenburn-bg-1"     . "#0C0C0C")
      ("zenburn-bg-05"    . "#121212")
      ("zenburn-bg"       . "#1C1C1C")
      ("zenburn-bg+05"    . "#222222")
      ("zenburn-bg+1"     . "#2C2C2C")
      ("zenburn-bg+2"     . "#3C3C3C")
      ("zenburn-bg+3"     . "#4C4C4C")
      ("zenburn-red+1"    . "#DCA3A3")
      ("zenburn-red"      . "#CC9393")
      ("zenburn-red-1"    . "#BC8383")
      ("zenburn-red-2"    . "#AC7373")
      ("zenburn-red-3"    . "#9C6363")
      ("zenburn-red-4"    . "#8C5353")
      ("zenburn-orange"   . "#DFAF8F")
      ("zenburn-yellow"   . "#F0DFAF")
      ("zenburn-yellow-1" . "#E0CF9F")
      ("zenburn-yellow-2" . "#D0BF8F")
      ("zenburn-yellow-4" . "#B09F6F")
      ("zenburn-green-2"  . "#4F6F4F")
      ("zenburn-green-1"  . "#5F7F5F")
      ("zenburn-green"    . "#7F9F7F")
      ("zenburn-green+1"  . "#8FB28F")
      ("zenburn-green+2"  . "#9FC59F")
      ("zenburn-green+3"  . "#AFD8AF")
      ("zenburn-green+4"  . "#BFEBBF")
      ("zenburn-cyan"     . "#93E0E3")
      ("zenburn-blue+1"   . "#94BFF3")
      ("zenburn-blue"     . "#8CD0D3")
      ("zenburn-blue-1"   . "#7CB8BB")
      ("zenburn-blue-2"   . "#6CA0A3")
      ("zenburn-blue-3"   . "#5C888B")
      ("zenburn-blue-4"   . "#4C7073")
      ("zenburn-blue-5"   . "#366060")
      ("zenburn-magenta"  . "#DC8CC3"))
    "List of Zenburn colors.
     Each element has the form (NAME . HEX).

     `+N' suffixes indicate a color is lighter.
     `-N' suffixes indicate a color is darker.

     This overrides the colors provided by the `zenburn-theme' package.")


  :config
  (load-theme 'zenburn t)

  (make-face 'ds/esh-autosuggest-face)

  ;; default face customizations
  (zenburn-with-color-variables
    ;; darker region selection
    (set-face-attribute 'region nil :background "#3c3c45" :inverse-video t)
    ;; flat mode and header lines
    (set-face-attribute 'header-line nil :background zenburn-bg+1 :box nil)
    (set-face-attribute 'mode-line nil :background zenburn-bg+1 :box nil)
    (set-face-attribute 'mode-line-inactive nil :foreground zenburn-bg+3 :background zenburn-bg+1 :box nil)
    (set-face-attribute 'fringe nil :background zenburn-bg+1)
    ;; italic comments
    (set-face-attribute 'font-lock-comment-face nil :slant 'italic)
    ;; eldoc function face
    (set-face-attribute 'eldoc-highlight-function-argument nil :foreground zenburn-blue-1)
    ;; set the verticle border color
    (set-face-attribute 'vertical-border nil :foreground zenburn-bg-1)
    (set-face-attribute 'ds/esh-autosuggest-face nil
                           :foreground zenburn-fg-1
                           :background zenburn-bg))

  ;; flycheck use straight underline instead of wave
  (with-eval-after-load 'flycheck
    (zenburn-with-color-variables
      (set-face-attribute 'flycheck-error nil :underline `(:style line :color ,zenburn-red-1))
      (set-face-attribute 'flycheck-warning nil :underline `(:style line :color ,zenburn-yellow-2))
      (set-face-attribute 'flycheck-info nil :underline `(:style line :color ,zenburn-blue-2))))

  ;; company faces
  (with-eval-after-load 'company
    (zenburn-with-color-variables
      (set-face-attribute 'company-preview nil :background zenburn-green+2 :foreground zenburn-bg)
      (set-face-attribute 'company-preview-search nil :background zenburn-blue :foreground zenburn-bg)))

  (with-eval-after-load 'company-template
    (zenburn-with-color-variables
      (set-face-attribute 'company-template-field nil :background zenburn-yellow-1 :foreground zenburn-bg)))

  ;; faces for ledger mode
  (with-eval-after-load 'ledger-mode
    (zenburn-with-color-variables
      (set-face-attribute 'ledger-font-auto-xact-face nil :foreground zenburn-yellow)
      (set-face-attribute 'ledger-font-periodic-xact-face nil :foreground zenburn-green+3)
      (set-face-attribute 'ledger-font-xact-cleared-face nil :foreground zenburn-fg)
      (set-face-attribute 'ledger-font-xact-pending-face nil :foreground zenburn-yellow-2)
      ;; (set-face-attribute 'ledger-font-xact-open-face nil :foreground zenburn-bg-1)
      (set-face-attribute 'ledger-font-payee-uncleared-face nil :foreground zenburn-fg-1)
      (set-face-attribute 'ledger-font-payee-pending-face nil :foreground zenburn-yellow-2)
      (set-face-attribute 'ledger-font-pending-face nil :foreground zenburn-yellow-2)
      (set-face-attribute 'ledger-font-other-face nil :foreground zenburn-blue-1)
      (set-face-attribute 'ledger-font-posting-account-face nil :foreground zenburn-blue-3 )
      (set-face-attribute 'ledger-font-posting-amount-face nil :foreground zenburn-green+4 )
      (set-face-attribute 'ledger-font-posting-date-face nil :foreground zenburn-orange :underline t)
      (set-face-attribute 'ledger-font-report-clickable-face nil :foreground zenburn-fg+1)))

  ;; highlight-parentheses
  (with-eval-after-load 'highlight-parentheses
    (zenburn-with-color-variables
      (setq hl-paren-background-colors `(,zenburn-bg-2 ,zenburn-bg-1 ,zenburn-bg-05 ,zenburn-bg+05 ,zenburn-bg+1 ,zenburn-bg+2 ,zenburn-bg+3 ,zenburn-fg-1))
      (setq hl-paren-colors `(,zenburn-red-2 ,zenburn-green ,zenburn-orange ,zenburn-blue ,zenburn-yellow ,zenburn-cyan ,zenburn-magenta ,zenburn-fg+1))))

  ;; faces for avy
  (with-eval-after-load 'avy
    (zenburn-with-color-variables
      (set-face-attribute 'avy-background-face nil :foreground zenburn-fg-1 :background zenburn-bg-1)
      (set-face-attribute 'avy-lead-face-0 nil :foreground zenburn-blue-1 :background zenburn-bg :box `(:line-width -2 :color ,zenburn-fg) :weight 'normal :slant 'italic)
      (set-face-attribute 'avy-lead-face-1 nil :foreground zenburn-green-2 :background zenburn-bg :box `(:line-width -2 :color ,zenburn-fg) :weight 'normal :slant 'italic)
      (set-face-attribute 'avy-lead-face-2 nil :foreground zenburn-yellow-4 :background zenburn-bg :box `(:line-width -2 :color ,zenburn-fg) :weight 'normal :slant 'italic)
      (set-face-attribute 'avy-lead-face nil :foreground zenburn-red-1 :background zenburn-bg :box `(:line-width -2 :color ,zenburn-fg) :weight 'normal :slant 'italic)))

  (with-eval-after-load 'ivy
    (zenburn-with-color-variables
      (set-face-attribute 'ivy-subdir nil :foreground zenburn-blue-1 :background nil :weight 'bold)
      (set-face-attribute 'ivy-remote nil :foreground zenburn-red-1 :background nil :weight 'bold)
      (set-face-attribute 'ivy-current-match nil :foreground nil :background zenburn-bg+3 :box zenburn-blue :underline nil)
      (set-face-attribute 'ivy-minibuffer-match-face-1 nil :background nil :box zenburn-green-1 :underline nil)
      (set-face-attribute 'ivy-minibuffer-match-face-2 nil :background nil :box zenburn-green-1 :underline nil)
      (set-face-attribute 'ivy-minibuffer-match-face-3 nil :background nil :box zenburn-red-1 :underline nil)
      (set-face-attribute 'ivy-minibuffer-match-face-4 nil :background nil :box zenburn-yellow-1 :underline nil))))

(use-package powerline
  :ensure t
  :demand t
  :after zenburn-theme
  :init
  (defmacro ds/powerline-sep (TYPE DIR FACE1 FACE2)
    `(,(intern (format "powerline-%s-%s" TYPE DIR)) ,FACE1 ,FACE2 powerline-height))

  (defmacro ds/powerline-widget (SEP FACE FUNC &optional DIRS PADDING &rest ARGS)
    (let* ((dir-left (cond ((equal DIRS 'left) 'left)
                           ((equal DIRS 'right) 'right)
                           (DIRS 'right)
                           (t 'left)))
           (dir-right (cond ((equal DIRS 'left) 'left)
                            ((equal DIRS 'right) 'right)
                            (DIRS 'left)
                            (t 'right)))
           (sep-left `(ds/powerline-sep ,SEP ,dir-left 'mode-line ,FACE))
           (sep-right `(ds/powerline-sep ,SEP ,dir-right ,FACE 'mode-line))
           (widget ()))
      (if PADDING
          (push `(powerline-raw " " 'mode-line) widget))
      (push sep-right widget)
      (if ARGS
          (push `(,FUNC ,@ARGS ,FACE) widget)
        (push `(,FUNC ,FACE) widget))
      (push sep-left widget)
      (if PADDING
          (push `(powerline-raw " " 'mode-line) widget))
      `(list ,@widget)))

  (defmacro ds/powerline-tab (FACE FUNC &rest ARGS)
    `(ds/powerline-widget chamfer ,FACE ,FUNC t nil ,@ARGS))

  (defmacro ds/powerline-button (FACE FUNC &rest ARGS)
    `(ds/powerline-widget bar ,FACE ,FUNC t t ,@ARGS))

  (defmacro ds/powerline-tag (SEP DIR FACE FUNC &rest ARGS)
    `(ds/powerline-widget ,SEP ,FACE ,FUNC ,DIR nil ,@ARGS))



  (defmacro ds/powerline-section (SEP DIR &rest PARTS)
    (let* ((section '())
           (last-face 'mode-line)
           (last-was-tag))
      (dolist (part PARTS)
        (let ((face (car part))
              (face-section ())
              (is-tag (member ':tag (cdr part))))
          ;; if this is a tag, add a buffer of modeline face around this
          (if is-tag
              (progn
                ;; if the last section was not a tag, add in the initial separator
                (if (not last-was-tag)
                    (setq face-section `(,@face-section ,(macroexpand `(ds/powerline-sep ,SEP ,DIR ,last-face 'mode-line)))))
                ;; always put in a sep from modeline to tag face
                (setq face-section `(,@face-section ,(macroexpand `(ds/powerline-sep ,SEP ,DIR 'mode-line ,face)))))
            ;; if this is not a tag, pu in a sep that goes from the last face to this face
            (setq face-section `(,@face-section ,(macroexpand `(ds/powerline-sep ,SEP ,DIR ,last-face ,face)))))
          (dolist (thing (cdr part))
            (when (and thing (listp thing))
              (let* ((has-test (plist-member thing ':cond))
                     (prefix (or (plist-get thing ':prefix) " "))
                     (prefix (if (equal "" prefix) nil prefix))
                     (suffix (plist-get thing ':suffix))
                     (test (plist-get thing ':cond))
                     (cmd (or (plist-get thing ':cmd) 'powerline-raw))
                     (args (plist-get thing ':args)))
                (when (or (not has-test) (eval test))
                  (if prefix (setq face-section `(,@face-section ,(if has-test `(if ,test (powerline-raw ,prefix ,face)) `(powerline-raw ,prefix ,face)))))
                  (setq face-section `(,@face-section ,(if has-test `(if ,test (,cmd ,@args ,face)) `(,cmd ,@args ,face))))
                  (if suffix (setq face-section `(,@face-section ,(if has-test `(if ,test (powerline-raw ,suffix ,face)) `(powerline-raw ,suffix ,face)))))))))
          (when (> (length face-section) (if is-tag (if last-was-tag 2 3) 1))
            (setq section `(,@section ,@face-section (powerline-raw " " ,face)))
            (if is-tag
                (setq section `(,@section ,(macroexpand `(ds/powerline-sep ,SEP ,DIR ,face 'mode-line)))))
            (setq last-face (if is-tag 'mode-line face)))
          (setq last-was-tag is-tag)))
      (setq section `(,@section ,(macroexpand `(ds/powerline-sep ,SEP ,DIR ,last-face 'mode-line))))
      `(list ,@section)))

  (defvar ds/powerline-breakpoint-small 820
    "Small breakpoint for powerline.")
  (defvar ds/powerline-breakpoint-medium 1080
    "Small breakpoint for powerline.")

  (zenburn-with-color-variables
    (defface ds/powerline-green
      `((t (:foreground ,zenburn-bg-2 :background ,zenburn-green-2 :inherit mode-line)))
      "Powerline Green."
      :group 'powerline)
    (defface ds/powerline-blue
      `((t (:foreground ,zenburn-bg-2 :background ,zenburn-blue-5 :inherit mode-line)))
      "Powerline Blue."
      :group 'powerline)
    (defface ds/powerline-red
      `((t (:foreground ,zenburn-bg-2 :background ,zenburn-red-4 :inherit mode-line)))
      "Powerline Red."
      :group 'powerline)
    (defface ds/powerline-yellow
      `((t (:foreground ,zenburn-bg-2 :background ,zenburn-yellow-4 :inherit mode-line)))
      "Powerline Yellow."
      :group 'powerline)
    (defface ds/powerline-orange
      `((t (:foreground ,zenburn-bg-2 :background ,zenburn-orange :inherit mode-line)))
      "Powerline Orange."
      :group 'powerline)
    (defface ds/powerline-cyan
      `((t (:foreground ,zenburn-bg-2 :background ,zenburn-cyan :inherit mode-line)))
      "Powerline Cyan."
      :group 'powerline)
    (defface ds/powerline-magenta
      `((t (:foreground ,zenburn-bg-2 :background ,zenburn-magenta :inherit mode-line)))
      "Powerline Magenta."
      :group 'powerline)
    (defface ds/powerline-gray
      `((t (:foreground ,zenburn-fg-05 :background ,zenburn-bg+2 :inherit mode-line)))
      "Powerline Gray."
      :group 'powerline)
    (defface ds/powerline-light-gray
      `((t (:foreground ,zenburn-fg :background ,zenburn-bg+3 :inherit mode-line)))
      "Powerline Light Gray."
      :group 'powerline)
    (defface ds/powerline-inactive
      `((t (:foreground ,zenburn-bg+3 :background ,zenburn-bg+1 :italic :inherit mode-line-inactive)))
      "Powerline Inacive."
      :group 'powerline))

  (defun powerline-flycheck-face ()
    "Function to select appropriate face based on `flycheck-has-current-errors-p'."
    (if (bound-and-true-p flycheck-mode)
        (let* ((face (cond ((flycheck-has-current-errors-p 'error)
                            'ds/powerline-red)
                           ((flycheck-has-current-errors-p 'warning)
                            'ds/powerline-yellow)
                           ((flycheck-has-current-errors-p 'info)
                            'ds/powerline-blue))))
          (if (facep face) face
            (if (> (length flycheck-enabled-checkers) 0)
                'ds/powerline-green
              'ds/powerline-light-gray)))
      'ds/powerline-light-gray))

  (defun ds/extract-tramp-target (conn-type &optional part)
  (save-match-data
    (let ((dirname (eshell/pwd)))
      (and (string-match (concat conn-type ":\\([^@|:]+\\)@?\\([^@|:]*\\)") dirname)
           (let ((user (match-string 1 dirname))
                 (host (match-string 2 dirname)))
             (cond ((equal part 'user) user)
                   ((equal part 'host) host)
                   ((equal part 'all) (concat user "@" host))))))))

  :config

  (defun ds/powerline-theme ()
    "Setup the default mode-line."
    (interactive)
    (setq-default mode-line-format
                  '("%e"
                    (:eval
                     (let* (;; size info
                            (width (window-pixel-width))
                            (is-small (< width ds/powerline-breakpoint-small))
                            (is-medium (and (>= width ds/powerline-breakpoint-small)
                                            (< width ds/powerline-breakpoint-medium)))
                            (is-large (>= (window-pixel-width) ds/powerline-breakpoint-medium))
                            ;; window status
                            (active (powerline-selected-window-active))
                            (is-exwm-window (equal major-mode 'exwm-mode))
                            ;; faces
                            (mode-line (if active 'mode-line 'mode-line-inactive))
                            (inner-face (if active 'ds/powerline-gray 'ds/powerline-inactive))
                            (flycheck-face (if active (powerline-flycheck-face) 'ds/powerline-inactive))
                            (notification-face (if active 'ds/powerline-blue 'ds/powerline-inactive))
                            (tramp-ssh-face (if active
                                                (if (equal "root" (ds/extract-tramp-target "ssh" 'user))
                                                    'ds/powerline-yellow
                                                  'ds/powerline-green)
                                              'ds/powerline-inactive))
                            (tramp-su-face (if active 'ds/powerline-yellow 'ds/powerline-inactive))
                            (tramp-sudo-face (if active 'ds/powerline-red 'ds/powerline-inactive))
                            ;; tramp detection
                            (tramp-ssh (string-match "ssh:" (eshell/pwd)))
                            (tramp-sudo (string-match "sudo:" (eshell/pwd)))
                            (tramp-su (string-match "su:" (eshell/pwd)))
                            (is-tramp (or tramp-ssh tramp-sudo tramp-su))
                            ;; mode filtering
                            (active-modes (mapc (lambda (mode)
                                                  (condition-case nil
                                                      (if (and (symbolp mode) (symbol-value mode))
                                                          (add-to-list 'active-modes mode))
                                                    (error nil) ))
                                                minor-mode-list))
                            ;; left side
                            (lhs (ds/powerline-section
                                   arrow left
                                   (mode-line
                                    (:args (" ") :prefix "")
                                    (:cond (not is-exwm-window) :args ("%*") :prefix "")
                                    (:cond (and (not is-exwm-window)
                                                is-large)
                                           :cmd powerline-buffer-size)
                                    (:cond (and (not is-exwm-window)
                                                is-large)
                                           :args (mode-line-mule-info)))
                                   (tramp-ssh-face
                                    :tag
                                    (:cond tramp-ssh :args ((concat
                                                             "SSH "
                                                             (ds/extract-tramp-target "ssh" 'all)))))
                                   (tramp-su-face
                                    :tag
                                    (:cond tramp-su :args ((concat
                                                            "SU "
                                                            (ds/extract-tramp-target "su" 'user)))))
                                   (tramp-sudo-face
                                    :tag
                                    (:cond tramp-sudo :args ((concat
                                                              "SUDO "
                                                              (ds/extract-tramp-target "sudo" 'user)))))
                                   (flycheck-face
                                    (:cmd powerline-buffer-id :prefix "")
                                    (:cond (and (boundp 'which-function-mode)
                                                which-function-mode
                                                is-large)
                                           :args (which-func-format)
                                           :prefix " / "))
                                   (inner-face
                                    (:cond (and (boundp 'erc-modified-channels-object) is-large)
                                           :args (erc-modified-channels-object)
                                           :prefix "")
                                    (:cmd powerline-major-mode)
                                    (:cond is-large :cmd powerline-process)
                                    (:cond (or is-large is-medium) :cmd powerline-minor-modes)
                                    (:cond is-large :cmd powerline-narrow))
                                   (mode-line
                                    (:cond (or is-large is-medium) :cmd powerline-vc :prefix ""))))
                            ;; right side
                            (rhs (ds/powerline-section
                                  arrow right
                                  (inner-face
                                   (:cond (and (or (> (length global-mode-string) 1)
                                                   (> (length (car global-mode-string)) 0))
                                               is-large)
                                          :args (global-mode-string)))
                                  (notification-face
                                   (:cond eosd-notification-list :args ((format " %d" (length eosd-notification-list)))))
                                  (flycheck-face
                                   (:cond (not is-exwm-window) :args ("%l %c")))
                                  (mode-line
                                   (:cond (not is-exwm-window) :args ("%p"))
                                   (:args (" ") :prefix "")))))
                            (concat (powerline-render lhs)
                                    (powerline-fill mode-line (powerline-width rhs))
                                    (powerline-render rhs)))))))

  (defun ds/powerline-set-height ()
    (setq powerline-height (frame-char-size)))

  (add-hook 'after-init-hook #'ds/powerline-set-height)

  (ds/powerline-theme))

(use-package try
  :ensure t)

(use-package fontawesome
  :ensure t
  :pin melpa
  :config
  (defun ds/vc-git-mode-line-string (orig-fn &rest args)
    "Replace Git in modeline with font-awesome git icon via ORIG-FN and ARGS."
    (let ((str (apply orig-fn args)))
      (concat [#xf126] ":" (substring-no-properties str 4))))

  (advice-add #'vc-git-mode-line-string :around #'ds/vc-git-mode-line-string))

(use-package smooth-scrolling
  :ensure t
  :config
  (smooth-scrolling-mode 1))

(use-package autorevert
  :diminish auto-revert-mode
  :config
  (global-auto-revert-mode))

(use-package highlight-parentheses
  :ensure t
  :diminish highlight-parentheses-mode
  :config
  (add-hook 'emacs-lisp-mode-hook
          '(lambda ()
             (highlight-parentheses-mode))))

(use-package subword
  :diminish subword-mode
  :config
  (global-subword-mode))

(use-package winner
  :diminish winner-mode
  :config
  (winner-mode))

(use-package adaptive-wrap
  :ensure t
  :pin gnu
  :init
  (defvar adaptive-wrap-extra-indent 2)
  :config
  (add-hook 'visual-line-mode-hook
            '(lambda ()
               (adaptive-wrap-prefix-mode (if visual-line-mode 1 -1)))))

(use-package linum-relative
  :ensure t
  :pin melpa-stable
  :bind (("C-x l" . linum-relative-toggle))
  :diminish linum-relative-mode
  :demand t
  :init
  (defvar linum-relative-current-symbol "")
  (defvar linum-relative-format "%3s "))

(use-package dired
  :config
  (setq dired-listing-switches "-lha --group-directories-first"))

(use-package dired-subtree
  :ensure t
  :commands (dired-subtree-toggle dired-subtree-cycle)
  :bind (:map dired-mode-map
              ("i" . dired-subtree-toggle))
  :config
  (setq dired-subtree-use-backgrounds nil))

(use-package uniquify
  :config
  (customize-set-variable 'uniquify-buffer-name-style 'forward))

(use-package magit
  :ensure t
  :pin melpa-stable
  :config
  (setq magit-merge-arguments '("--no-ff"))

  (defvar my-git-command-map
    (let ((map (make-sparse-keymap)))
      (define-key map "g" 'magit-status)
      (define-key map (kbd "C-g") 'magit-status)
      (define-key map "l" 'magit-list-repositories)
      (define-key map "f" 'magit-fetch-current)
      (define-key map "!" 'magit-blame)
      (define-key map "c" 'magit-checkout)
      (define-key map (kbd "C-r") 'magit-rebase-step)
      (define-key map (kbd "C-f") 'magit-pull)
      (define-key map (kbd "C-p") 'magit-push)
      (define-key map (kbd "z z") 'magit-stash)
      (define-key map (kbd "z p") 'magit-stash-pop)
      (define-key map (kbd "C-t") 'git-timemachine)
      (define-key map (kbd "C-c") 'magit-create-branch)
      map)
    "Keymap of commands to load magit.")

  (define-key global-map (kbd "C-c g") my-git-command-map)
  (define-key global-map (kbd "C-c C-g") my-git-command-map)

  (define-key magit-mode-map [remap previous-line] 'magit-previous-line)
  (define-key magit-mode-map [remap next-line] 'magit-next-line)


  (setq global-magit-file-mode        t
        magit-log-highlight-keywords  t
        magit-diff-highlight-keywords t)

  (add-hook 'magit-popup-mode-hook
            (lambda()
              (fit-window-to-buffer))))

(use-package git-timemachine
  :ensure t
  :pin melpa-stable)

(use-package gl-conf-mode
  :ensure t
  :pin melpa
  :defer t)

(use-package window-purpose
  :ensure t
  :pin melpa-stable
  :config
  (define-key purpose-mode-map (kbd "C-x b") nil)
  (define-key purpose-mode-map (kbd "C-x C-f") nil))

(use-package hyperbole
  :ensure t
  :disabled)

(use-package org
  :ensure org-plus-contrib
  :mode (("\\.org$" . org-mode))
  :demand t
  :pin org
  :init
  (defvar org-directory "~/org" "Directory for org files.")
  (defvar org-agenda-directory "~/org/agenda" "Directory for org files.")
  (defvar org-mobile-directory "~/.org-mobile" "Directory for mobile org files.")
  (defvar org-time-clocksum-format "%d:%.02d")
  (setq org-journal-dir (concat org-directory "/journal/"))
  :config
  (condition-case nil
      (make-directory org-journal-dir t) ; make the org and journal dirs if they are not there already
    (error nil))
  (condition-case nil
      (make-directory org-mobile-directory t) ; make the org and journal dirs if they are not there already
    (error nil))

  (defun org-agenda-reload ()
    "Reset org agenda files by rescanning the org directory."
    (interactive)
    (setq org-agenda-files (directory-files-recursive org-agenda-directory "\\.org\\|[0-9]\\{8\\}"))
    (setq org-refile-targets '((org-agenda-files . (:level . 1)))))

  (org-agenda-reload)
  (setq org-agenda-file-regexp "\\([^.].*\\.org\\)\\|\\([0-9]+\\)")

  (setq org-log-done 'time)
  (setq org-enforce-todo-dependencies t)
  (setq org-agenda-dim-blocked-tasks t)
  (setq org-catch-invisible-edits t)

  (setq org-clock-idle-time 15)
  (setq org-clock-mode-line-total 'current)
  (message "setting org clock face")
  (add-hook 'org-clock-in-prepare-hook
            (lambda ()
              (set-face-attribute 'org-mode-line-clock nil :foreground nil :background nil :underline nil :box nil)))
  (message "set org clock face")
  (setq org-log-into-drawer "LOGBOOK")
  (setq org-clock-into-drawer "LOGBOOK")
  (setq org-duration-format '(("h" . t) (special . 2)))
  (setq org-src-window-setup 'current-window)

  ;; Resume clocking task when emacs is restarted
  (org-clock-persistence-insinuate)
  ;; Save the running clock and all clock history when exiting Emacs, load it on startup
  (setq org-clock-persist t)
  ;; Resume clocking task on clock-in if the clock is open
  (setq org-clock-in-resume t)
  ;; Do not prompt to resume an active clock, just resume it
  (setq org-clock-persist-query-resume nil)
  ;; Sometimes I change tasks I'm clocking quickly - this removes clocked tasks
  ;; with 0:00 duration
  (setq org-clock-out-remove-zero-time-clocks t)
  ;; Clock out when moving task to a done state
  (setq org-clock-out-when-done t)
  ;; Enable auto clock resolution for finding open clocks
  (setq org-clock-auto-clock-resolution (quote when-no-clock-is-running))
  ;; Include current clocking task in clock reports
  (setq org-clock-report-include-clocking-task t)
  ;; use pretty things for the clocktable
  (setq org-pretty-entities t)

  (setq org-todo-keywords
        '((sequence "TODO(t)" "IN-PROGRESS(i!)" "WAITING(w@)" "|" "WILL-NOT-IMPLEMENT(k@)" "DONE(d)")
          (sequence "BUG(b)" "RESOLVING(r!)" "|" "NON-ISSUE(n@)" "PATCHED(p)")))

  ;; defaut capture file
  (setq org-default-notes-file (concat org-directory "/todo.org"))

  (setq org-capture-templates
        '(("t" "Todo" entry (file+headline (concat org-directory "/todo.org") "Todo") "* TODO %?\n  SCHEDULED: %^{Schedule}t\n  %A")
          ("n" "Note" entry (file+headline (concat org-directory "/notes.org") "Notes") "* %? %U\n  %i")))

  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'after-save-hook 'org-babel-tangle nil 'local-please)))

  (setq org-ditaa-jar-path "/usr/share/java/ditaa/ditaa-0_10.jar")
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((shell . t)
     (ditaa . t)))

  ;; expand logbook on org all expand
  (defun ds/expand-logbook-drawer ()
    "Expand the closest logbook drawer."
    (interactive)
    (search-forward ":LOGBOOK:")
    (org-cycle))

  (defun ds/org-logbook-cycle-hook (ds/drawer-curr-state)
    "When the MY/VAR/CURR-STATE is \"all\", open up logbooks."
    (interactive)
    (message "State changed")
    (when (eq ds/drawer-curr-state "all")
      (ds/expand-logbook-drawer)))

  (add-hook 'org-cycle-hook 'ds/org-logbook-cycle-hook))

(use-package org-bullets
  :ensure t
  :pin melpa-stable
  :config
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

(use-package projectile
  :ensure t
  ; :delight '(:eval (concat " " (projectile-project-name)))
  :pin melpa-stable
  :init
  (defvar projectile-remember-window-configs t)
  :config
  (setq projectile-mode-line '(:eval
   (if (file-remote-p default-directory)
       " NoProj"
     (format " Proj[%s]"
             (projectile-project-name)))))
  (projectile-global-mode))

(use-package multiple-cursors
  :ensure t
  :pin melpa-stable
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)))

(use-package undo-tree
  :ensure t
  :pin gnu
  :diminish undo-tree-mode
  :config
  (global-undo-tree-mode))

(use-package ace-window
  :ensure t
  :pin melpa-stable
  :disabled
  :bind (("C-x o" . ace-window))
  :config
  (setq aw-scope 'frame))

(use-package switch-window
  :ensure t
  :init
  (defun ds/switch-window (arg)
    (interactive "P")
    (if arg (switch-window-then-swap-buffer 0)
      (switch-window)))
  :bind (("C-x o" . ds/switch-window))
  :config
  (setq switch-window-threshold 6)
  (setq switch-window-increase 4)
  ;(setq switch-window-input-style 'minibuffer)
  )

(use-package exec-path-from-shell
  :ensure t
  :demand
  :config
  (progn
    (message "setting up exec path")
    (exec-path-from-shell-initialize)
    (message "set up exec path")))

(use-package flx
  :ensure t
  :pin melpa-stable)

(use-package hydra
  :ensure t
  :pin melpa-stable
  :config
  (defhydra hydra-zoom (global-map "C-c z")
    "zoom"
    ("g" text-scale-increase "in")
    ("l" text-scale-decrease "out"))
  (defhydra hydra-muti-cursor (global-map "C-c n" :hint nil)
  "
^Mark^
^^^^^^^^-----------------------------------------------------------------
_n_: next    
_p_: previous
"
    ("n" mc/mark-next-like-this)
    ("p" mc/mark-previous-like-this)))

(use-package avy
  :ensure t
  :pin melpa-stable
  :bind (("C-c j j" . avy-goto-char-in-line)
         ("C-c j l" . avy-goto-line)
         ("C-c j w" . avy-goto-word-or-subword-1)
         ("C-c j c" . avy-goto-char))
  :config
  (setq avy-keys '(?t ?n ?s ?e)))

(use-package smex
  :ensure t
  :pin melpa-stable)

(use-package ivy
  :ensure t
  :demand t
  :pin melpa-stable
  :diminish (ivy-mode . "")
  :bind (("C-x C-b" . ivy-switch-buffer)
         :map ivy-minibuffer-map
         ("C-'" . ivy-avy)
         ("C-e" . ivy-alt-done))
  :config
  (ivy-mode 1)
  ;; add ‘recentf-mode’ and bookmarks to ‘ivy-switch-buffer’.
  (setq ivy-use-virtual-buffers t)
  ;; recursive minibuffer
  (setq enable-recursive-minibuffers t)
  ;; count display
  (setq ivy-count-format "(%d/%d) ")
  ;; wrap
  (setq ivy-wrap t)
  ;; number of result lines to display
  (setq ivy-height 30)
  ;; no regexp by default
  (setq ivy-initial-inputs-alist nil)
  ;; configure regexp engine.
  (setq ivy-re-builders-alist
        ;; allow input not in order
        '((t . ivy--regex-fuzzy)))

  (add-hook
   'ivy-mode-hook
   (lambda ()
     (zenburn-with-color-variables
       (set-face-attribute 'ivy-subdir nil :foreground zenburn-blue-1 :background nil :weight 'bold)
       (set-face-attribute 'ivy-remote nil :foreground zenburn-red-1 :background nil :weight 'bold)
       (set-face-attribute 'ivy-current-match nil :foreground nil :background zenburn-bg+3 :box zenburn-blue :underline nil))))
  )

(use-package ivy-hydra
  :ensure t
  :pin melpa-stable)

(use-package counsel
  :ensure t
  :bind (("M-x" . counsel-M-x)
         ("C-x C-f" . counsel-find-file)
         :map read-expression-map
         ("C-r" . counsel-minibuffer-history))
  :config
  (push (concat (getenv "HOME") "/.local/share/applications/") counsel-linux-apps-directories)
  (defun ds/counsel-linux-app-format-function (name comment exec)
    "Default Linux application name formatter.
NAME is the name of the application, COMMENT its comment and EXEC
the command to launch it."
    (format "% -45s %s"
            (propertize name 'face 'font-lock-builtin-face)
            (or comment "")))

  (setq counsel-linux-app-format-function #'ds/counsel-linux-app-format-function))

(use-package counsel-projectile
  :ensure t
  :config
  (counsel-projectile-mode))

(use-package swiper
  :ensure t
  :pin melpa-stable
  :bind (("C-c s" . swiper))
  :config
  (add-to-list 'ivy-re-builders-alist '((swiper . ivy--regex-plus))))

(use-package sql
  :config
  (add-hook 'sql-interactive-mode-hook
            (lambda ()
              (toggle-truncate-lines t))))

(use-package nginx-mode
  :ensure t)

(use-package direnv
  :ensure
  :config
  (direnv-mode)
  (add-hook 'eshell-directory-change-hook #'direnv-update-directory-environment))

(use-package lsp-mode
  :ensure t
  :config

  ;(require 'lsp-flycheck)

  (use-package markdown-mode
    :ensure t
    :config
    (use-package lsp-ui-flycheck
      :ensure lsp-ui
      :disabled
      :config
      (add-hook 'lsp-after-open-hook (lambda () (lsp-ui-flycheck-enable 1)))))

  (use-package company-lsp
    :disabled
    :ensure t
    :pin melpa
    :config
    (push 'company-lsp company-backends)))

(use-package flycheck
  :ensure t
  :demand t
  :init
  (defun ds/toggle-flycheck-errors ()
    (interactive)
    (if (get-buffer flycheck-error-list-buffer)
        (kill-buffer flycheck-error-list-buffer)
      (flycheck-list-errors)))
  (setq-default flycheck-emacs-lisp-load-path 'inherit)
  :bind (:map flycheck-command-map
              ("l" . ds/toggle-flycheck-errors))
  :config
  ;; enable flycheck everywhere
  (add-hook 'after-init-hook #'global-flycheck-mode)
  (setq-default flycheck-disabled-checkers
                (append flycheck-disabled-checkers
                        '(javascript-jshint)))
  (setq flycheck-display-errors-delay 0.4)

  (defun ds/use-eslint-from-node-modules ()
    (setq-local flycheck-javascript-eslint-executable (ds/find-eslint-executable)))

  (add-hook 'flycheck-mode-hook #'ds/use-eslint-from-node-modules)

  (defun ds/kill-flycheck-popup ()
    (if (get-buffer flycheck-error-list-buffer)
        (kill-buffer flycheck-error-list-buffer)))

  (defun ds/flycheck-popup ()
    (if (and (bound-and-true-p flycheck-mode)
             flycheck-enabled-checkers)
        (let ((errors (seq-filter
                       (lambda (val) (eq (flycheck-error-level val) 'error))
                       flycheck-current-errors)))
          (if errors (flycheck-list-errors)
            ;; if there are no errors, hide the flycheck popup buffer
            (ds/kill-flycheck-popup)))))


  (defun ds/flycheck-close-unused-list (&rest _)
    (if (and (not (equal (buffer-name) flycheck-error-list-buffer))
             (not (bound-and-true-p flycheck-mode)))
        (ds/kill-flycheck-popup)))

  )

(use-package flycheck-pos-tip
  :ensure t
  :after flycheck
  :config
  (flycheck-pos-tip-mode))

(use-package company
  :ensure t
  :diminish company-mode
  :config
  (add-hook 'after-init-hook 'global-company-mode)
  (setq company-dabbrev-downcase nil)
  (setq company-show-numbers t)
  (setq company-search-regexp-function #'company-search-flex-regexp)
  (setq company-tooltip-limit 20) ; bigger popup window
  (setq company-idle-delay .4)    ; decrease delay before autocompletion popup shows
  (setq company-echo-delay 0))    ; remove annoying blinking

(use-package evil-nerd-commenter
  :ensure t
  :pin melpa-stable
  :bind (("C-c C-/ C-/" . evilnc-comment-or-uncomment-lines)
         ("C-c C-/ C-l" . evilnc-comment-or-uncomment-to-the-line)
         ("C-c C-/ C-c" . evilnc-copy-and-comment-lines)
         ("C-c C-/ C-p" . evilnc-comment-or-uncomment-paragraphs)
         ("C-c C-_ C-_" . evilnc-comment-or-uncomment-lines)
         ("C-c C-_ C-l" . evilnc-comment-or-uncomment-to-the-line)
         ("C-c C-_ C-c" . evilnc-copy-and-comment-lines)
         ("C-c C-_ C-p" . evilnc-comment-or-uncomment-paragraphs)))

(use-package irony
  :ensure t
  :config
  (add-hook 'c-mode-hook 'irony-mode)
  (use-package irony-eldoc
    :ensure t
    :config
    (setq irony-eldoc-use-unicode t)
    (add-hook 'irony-mode-hook #'irony-eldoc)))

(use-package clang-format
  :ensure t)

(use-package go-mode
  :ensure t
  :bind (:map go-mode-map
              ("C-c D" . godoc-at-point))
  :config
  (defun ds/setup-cgo-32 ()
    "Setup local environment for the buffer so flycheck can still work.
This will break go-vet, so you may want to disable it."
    (interactive)
    (set (make-local-variable 'process-environment)
         (append '("CGO_CFLAGS_ALLOW=-m32" "GOBIN=" "CGO_ENABLED=1" "GOARCH=386") process-environment)))

  (defun ds/go-packages-native ()
    "Return a list of all installed Go packages.
It looks for archive files in /pkg/."
    (sort
     (delete-dups
      (cl-mapcan
       (lambda (pkgdir)
         (cl-mapcan (lambda (dir)
                      (mapcar (lambda (file)
                                (let ((sub (substring file (length pkgdir) -2)))
                                  (mapconcat #'identity (cdr (split-string sub "/")) "/")))
                              (if (file-directory-p dir)
                                  (directory-files dir t "\\.a$")
                                (if (string-match-p "\\.a$" dir)
                                    `(,dir)))))
                    (if (file-directory-p pkgdir)
                        (append (directory-files pkgdir t "\\.a$") (go--directory-dirs pkgdir)))))
       (apply 'append
              (mapcar (lambda (dir)
                        (delete nil (let ((pkgdir (concat dir "/pkg")))
                                      (mapcar (lambda (sub)
                                                (unless (or (string-match-p
                                                             "\\(dep\\|race\\|dyn\\|shared\\|include\\|obj\\|tool\\)"
                                                             sub)
                                                            (member sub '("." ".."))) (concat pkgdir "/" sub)))
                                              (directory-files pkgdir nil nil t))))) (go-root-and-paths)))))
     #'string<))

  (setq go-packages-function #'ds/go-packages-native)

  (defun ds/go-hook ()
    "Hook for go-mode."
    ;; call gofmt for every save
    (add-hook 'before-save-hook 'gofmt-before-save)
    ;; customize the compile command
    (if (not (string-match "go" compile-command))
        (set (make-local-variable 'compile-command)
             "go build -v && go test && go vet")))

  (add-hook 'go-mode-hook 'ds/go-hook))

(use-package go-eldoc
  :ensure t
  :pin melpa-stable
  :config
  (add-hook 'go-mode-hook 'go-eldoc-setup))

(use-package go-scratch
  :ensure t
  :config
  (defun ds/goscratch-display-output-buffer (&rest _)
    (let ((scratch-buf (get-buffer go-scratch-outbuf)))
      (if scratch-buf (display-buffer-below-selected scratch-buf nil))))

  (add-function :after (symbol-function 'go-scratch-eval-buffer) #'ds/goscratch-display-output-buffer)
  (add-function :after (symbol-function 'go-scratch--run-sentinal) #'ds/clear-minibuffer))

(use-package company-go
  :ensure t
  :config
  (setq company-go-insert-arguments nil)
  (setq company-go-show-annotation t)
  (add-hook 'go-mode-hook (lambda ()
                            (set (make-local-variable 'company-backends) '(company-go))
                            (company-mode))))

(use-package lsp-go
  :disabled
  :ensure t
  :config
  (add-hook 'go-mode-hook 'lsp-go-enable))

(use-package yaml-mode
  :ensure t
  :pin melpa-stable
  :config
  (add-to-list 'auto-mode-alist '("\\.yaml\\'" . yaml-mode))
  (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode)))

(use-package js
  :config
  (setq js-indent-level 2))

(use-package js2-mode
  :ensure t
  :pin melpa-stable
  :diminish js2-minor-mode
  :config
  (add-to-list 'auto-mode-alist '("\\.json$" . js-mode))
  (add-hook 'js-mode-hook 'js2-minor-mode)
  (add-hook 'js2-minor-mode-hook 'js2-mode-hide-warnings-and-errors)
  (setq-default js2-show-parse-errors nil)
  (setq-default js2-strict-missing-semi-warning nil))

(use-package lsp-javascript-typescript
  :disabled
  :ensure t
  :config
  (add-hook 'js-mode-hook #'lsp-javascript-typescript-enable))

(defun eslint-fix ()
  "Format the current file with ESLint."
  (interactive)
  (let ((eslint (ds/find-eslint-executable)))
    (if eslint
        (progn (call-process eslint nil "*ESLint Errors*" nil "--fix" buffer-file-name)
               (revert-buffer t t t))
      (message "ESLint not found."))))

(use-package js
  :config
  (add-hook 'js-mode-hook
            (lambda ()
              (add-hook 'after-save-hook 'eslint-fix nil t)))
  (add-hook 'web-mode-hook
            (lambda ()
              (add-hook 'after-save-hook 'eslint-fix nil t)))
  (add-hook 'vue-mode-hook
            (lambda ()
              (add-hook 'after-save-hook 'eslint-fix nil t))))

(use-package vue-mode
  :ensure t
  :pin melpa-stable
  :config
  (setq vue-modes
        '((:type template :name nil :mode web-mode)
          (:type template :name html :mode web-mode)
          (:type template :name jade :mode jade-mode)
          (:type template :name pug :mode pug-mode)
          (:type template :name slm :mode slim-mode)
          (:type template :name slim :mode slim-mode)
          (:type script :name nil :mode js-mode)
          (:type script :name js :mode js-mode)
          (:type script :name es6 :mode js-mode)
          (:type script :name babel :mode js-mode)
          (:type script :name coffee :mode coffee-mode)
          (:type script :name ts :mode typescript-mode)
          (:type script :name typescript :mode typescript-mode)
          (:type style :name nil :mode css-mode)
          (:type style :name css :mode css-mode)
          (:type style :name stylus :mode stylus-mode)
          (:type style :name less :mode less-css-mode)
          (:type style :name scss :mode css-mode)
          (:type style :name sass :mode ssass-mode)))
  (add-to-list 'auto-mode-alist '("\\.vue\\'" . web-mode)))

(use-package json-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("package\\.json\\'" . json-mode)))

(use-package web-mode
  :ensure t
  :pin melpa-stable
  :config
  (setq web-mode-code-indent-offset 2)
  (with-eval-after-load 'flycheck
    (flycheck-add-mode 'javascript-eslint 'web-mode))
  (with-eval-after-load 'eslint-fix
    (add-hook 'web-mode-hook
              (lambda ()
                (add-hook 'after-save-hook 'eslint-fix nil t))))

  (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode)))

(use-package protobuf-mode
  :ensure t
  :config
  (add-hook 'protobuf-mode-hook
            '(lambda ()
               (when (not (boundp 'protobuf-protoc))
                 (flycheck-define-checker protobuf-protoc
                   "A protobuf syntax checker using the protoc compiler.

     See URL `https://developers.google.com/protocol-buffers/'."
                   :command ("protoc" "--error_format" "gcc"
                             (eval (concat "--java_out=" (flycheck-temp-dir-system)))
                             ;; Add the file directory of protobuf path to resolve import directives
                             (eval (concat "--proto_path=" (file-name-directory (buffer-file-name))))
                             "--proto_path=/usr/local/include"
                             (eval (concat "--proto_path=" (getenv "GOPATH") "/src"))
                             (eval (concat "--proto_path=" (getenv "GOPATH") "/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis"))
                             source-inplace)
                   :error-patterns
                   ((info line-start (file-name) ":" line ":" column
                          ": note: " (message) line-end)
                    (error line-start (file-name) ":" line ":" column
                           ": " (message) line-end)
                    (error line-start
                           (message "In file included from") " " (file-name) ":" line ":"
                           column ":" line-end))
                   :modes protobuf-mode
                   :predicate buffer-file-name)))))

(use-package srefactor
  :ensure t
  :config
  (use-package srefactor-lisp
    :bind (:map emacs-lisp-mode-map
                ("C-c M-q" . srefactor-lisp-format-sexp)
                :map lisp-interaction-mode-map
                ("C-c M-q" . srefactor-lisp-format-sexp))))

(add-hook 'emacs-lisp-mode-hook #'electric-pair-local-mode)
(add-hook 'lisp-interaction-mode-hook #'electric-pair-local-mode)

(use-package znc
  :ensure t
  :defer t)

(use-package ledger-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("\\.ledger$" . ledger-mode))
  (add-to-list 'auto-mode-alist '("\\.ldg$" . ledger-mode))
  (add-to-list 'auto-mode-alist '("\\.rec$" . ledger-mode))

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((ledger . t)))

  (defun find-ledger-directory ()
    "Get directory with ledger files."
    (let ((ledgerrc (concat (getenv "HOME") "/.ledgerrc")))
      (if (file-readable-p ledgerrc)
          (let ((conffile (with-temp-buffer
                            (insert-file-contents ledgerrc)
                            (split-string (buffer-string) "\n")))
                (filename ""))
            (dolist (ln conffile filename)
              (message ln)
              (if (string-match "^--file" ln)
                  (setq filename (replace-regexp-in-string "^--file \\([[:graph:]]\+\\)" "\\1" ln))
                nil))
            (string-trim (shell-command-to-string
                          (concat
                           "dirname "
                           filename)))))))

  (defun look-for-ledger-schedule-file ()
    "See if there is a file in the same directory as this ledger file with the same basename and a \".rec\" extenxtion. If so, set the `ledger-schedule-file variable' to this file for the local buffer."
    (if (not (string= (buffer-name) ledger-schedule-buffer-name))
        (set-local-variable
         'ledger-schedule-file
         (replace-regexp-in-string
          "\\.\\(ledger\\|ldg\\)" ".rec" (buffer-file-name) nil 'literal))))

  (add-hook 'ledger-mode-hook #'look-for-ledger-schedule-file)


  (defun org-to-tc ()
    "Convert the current org file into a timeclock file for ledger."
    (message "Saving timeclock file")
    (let ((mkdir (concat "mkdir -p " (find-ledger-directory) "/timeclocks"))
          (cmdstr (concat "~/.emacs.d/bin/org2tc "
                          (buffer-file-name)
                          " > " (find-ledger-directory) "/timeclocks/"
                          (replace-regexp-in-string
                           (regexp-quote "\.org") ".timeclock" (buffer-name) nil 'literal)))
          (cleanup (concat "for file in $(find " (find-ledger-directory) "/timeclocks/ -size 0);"
                           "do rm $file; done")))
      (shell-command mkdir)
      (shell-command cmdstr)
      (shell-command cleanup)))


  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'after-save-hook 'org-to-tc nil 'local-please)))

  (setq ledger-reports
        '(("asset/liabilities" "ledger -f %(ledger-file) bal assets liabilities")
          ("profit/loss" "ledger -f %(ledger-file) bal income expenses")
          ("checkbook" "ledger -f %(ledger-file) reg personal:assets:checking")
          ("cc" "ledger -f %(ledger-file) reg personal:liabilities and visa")
          ("loans" "ledger -f %(ledger-file) reg personal:liabilities and loan personal:expense and loan")
          ("bal" "ledger -f %(ledger-file) bal")
          ("reg" "ledger -f %(ledger-file) reg")
          ("payee" "ledger -f %(ledger-file) reg @%(payee)")
          ("account" "ledger -f %(ledger-file) reg %(account)"))))

(use-package kubernetes
  :ensure t
  :demand t
  :commands (kubernetes-overview)
  :config
  (ds/popup-thing-display-settings "*kubernetes logs*" top 0 0.33)
  (setq kubernetes-poll-frequency 5))

(use-package pdf-tools
  :ensure t
  :pin melpa
  :config
  (pdf-tools-install))

(use-package pass
  :ensure t
  :config
  (use-package password-store-otp
    :ensure t
    :init

    (defun ds/password-store-get-otp (record)
      (interactive (list (password-store--completing-read)))
      (password-store-otp-token-copy record))

    (defun ds/pass-sentinel (process evt)
      (message "process %s evt %s" process evt)
      (with-current-buffer (process-buffer process)
        (if (equal evt "finished\n")
            (let ((password (car (s-lines (s-chomp (buffer-string))))))
              (kill-buffer)
              (password-store-clear)
              (kill-new password)
              (setq password-store-kill-ring-pointer kill-ring-yank-pointer)
              (message "Copied password to the kill ring. Will clear in %s seconds." (password-store-timeout))
              (setq password-store-timeout-timer
                    (run-at-time (password-store-timeout) nil 'password-store-clear))))
        (if (string-match-p "^exited abnormally" evt)
            (let ((err (s-chomp (buffer-string))))
              (kill-buffer)
              (error err)))))

    :config

    (defun password-store-copy (entry)
      "Add password for ENTRY to kill ring.

Clear previous password from kill ring.  Pointer to kill ring is
stored in `password-store-kill-ring-pointer'.  Password is cleared
after `password-store-timeout' seconds."
      (interactive (list (password-store--completing-read)))
      (make-process
       :name "pass"
       :buffer "pass-buffer"
       :command `(,password-store-executable "show" ,entry)
       :sentinel 'ds/pass-sentinel))

    (use-package auth-password-store
      :ensure t
      :demand t
      :config
      (add-to-list 'auth-sources 'password-store t)
      (auth-source-forget-all-cached))))

(use-package restclient
  :ensure t
  :config
  (ds/popup-thing-display-settings "*HTTP Response*" left 0 0.25))

(use-package exwm
  :ensure t
  :init
  (defun ds/exwm-set-name ()
    ;; (message "class: %s, instance: %s, title: %s, state: %s, type: %s" exwm-class-name exwm-instance-name exwm-title exwm-state exwm-window-type)
    (exwm-workspace-rename-buffer exwm-class-name))
  :config
  ;; auto rename new X window buffers
  (add-hook 'exwm-update-class-hook #'ds/exwm-set-name)
  ;; hide the mode-line of floating X windows
  (add-hook 'exwm-floating-setup-hook #'exwm-layout-hide-mode-line)
  (add-hook 'exwm-floating-exit-hook #'exwm-layout-show-mode-line)
  ;; 'C-s-n': Rename buffer
  (exwm-input-set-key (kbd "C-s-n") #'rename-buffer)
  ;; 'C-s-r': Reset
  (exwm-input-set-key (kbd "C-s-r") #'exwm-reset)
  ;; 'C-s-f': Toggle Fullscreen
  (exwm-input-set-key (kbd "C-s-f") #'exwm-layout-toggle-fullscreen)
  ;; do xinit stuff
  (start-process "" nil (concat user-emacs-directory "exwm/bin/xinitscript"))
  ;; disable flycheck for exwm buffers
  (add-hook 'exwm-mode-hook (lambda () (flycheck-mode -1))))

(use-package exwm
  :ensure t
  :config
  (defmacro ds/popup-thing (NAME BUFFER &rest BODY)
    "Make a popup thing with function NAME buffer name BUFFER executing BODY to create."
    (let* ((delete-func-sym (intern (concat (symbol-name NAME) "--delete"))))
      `(progn
         (defun ,delete-func-sym (&rest _)
           (let ((current-popup (get-buffer-window ,BUFFER)))
             (if (and current-popup
                      (> (length (window-list)) 1))
                 (delete-window current-popup))))
         (add-function :before (symbol-function 'exwm-workspace-switch) #',delete-func-sym)
         (defun ,NAME ()
           (interactive)
           (let* ((win (selected-window))
                  (current-popup (or (get-buffer-window ,BUFFER t)
                                     (get-buffer-window ,(concat " " BUFFER) t)))
                  (popup-buf (or (get-buffer ,BUFFER)
                                 (get-buffer ,(concat " " BUFFER))))
                  (is-x-window (if popup-buf
                                   (equal 'exwm-mode (with-current-buffer popup-buf major-mode)))))
             (if (equal win current-popup)
                 (delete-window current-popup)
               (if current-popup
                   (select-window current-popup)
                 (if popup-buf
                     (progn
                       (if is-x-window
                           (save-window-excursion
                             (with-current-buffer popup-buf
                               (exwm-workspace-move-window exwm-workspace--current exwm--id))))
                       (pop-to-buffer popup-buf))
                   (progn ,@BODY))))))))))

(use-package exwm
  :ensure t
  :init
  (defvar ds/exwm-previous-workspace nil
    "Stores previous workspace when switching in exwm")
  :config
  (setq exwm-workspace-number 10)
  ;; set up bindings to switch to workspaces
  (dotimes (i 10)
    (let* ((switch-binding (kbd (format "s-%d" i)))
           (move-binding (kbd (format "C-s-%d" i))))
      ;; use s-N to switch to a workspace number
      (exwm-input-set-key switch-binding
                          `(lambda ()
                             (interactive)
                             (exwm-workspace-switch-create ,i)))
      ;; use C-s-N to move the current window to a workspace
      (exwm-input-set-key move-binding
                          `(lambda ()
                             (interactive)
                             (exwm-workspace-move-window ,i)
                             (select-frame-set-input-focus exwm-workspace--current))))))

(use-package exwm
  :ensure t
  :init
  (defvar ds/exwm-previous-workspace nil
    "Stores previous workspace when switching in exwm")
  :config
  (defun ds/exwm-mark-previous (&rest _)
    "Save the current EXWM workspace index to `ds/exwm-previous-workspace'."
    (setq ds/exwm-previous-workspace exwm-workspace-current-index))

  (defun ds/exwm-workspace-toggle ()
    "Switch back to the previously active EXWM workspace."
    (interactive)
    (exwm-workspace-switch ds/exwm-previous-workspace))
  ;; (remove-function (symbol-function 'exwm-workspace-switch) #'ds/exwm-mark-previous)
  (add-function :before (symbol-function 'exwm-workspace-switch) #'ds/exwm-mark-previous)

  ;; use s-tab to switch workspaces back and forth
  (exwm-input-set-key (kbd "<s-tab>") #'ds/exwm-workspace-toggle)

  ;; fix magit for this key
  (with-eval-after-load 'magit
    (defun ds/exwm-fix-magit-workspace-toggle ()
      (define-key magit-status-mode-map (kbd "<s-tab>") #'ds/exwm-workspace-toggle))
    (add-hook 'magit-status-mode-hook #'ds/exwm-fix-magit-workspace-toggle)))

(use-package exwm
  :ensure t
  :config
  ;; 's-SPC': Launch application
  (exwm-input-set-key (kbd "s-SPC") #'counsel-linux-app)
  ;; 's-r': Run shell command
  (exwm-input-set-key (kbd "s-r")
                      (lambda (command)
                        (interactive (list (read-shell-command "$ ")))
                        (start-process-shell-command command nil command))))

(use-package exwm
  :ensure t
  :config
  ;; wrap windows when moving with windmove
  (setq windmove-wrap-around t)

  ;; s-[arrows] to move windows
  (exwm-input-set-key (kbd "<s-left>") #'windmove-left)
  (exwm-input-set-key (kbd "<s-down>") #'windmove-down)
  (exwm-input-set-key (kbd "<s-up>") #'windmove-up)
  (exwm-input-set-key (kbd "<s-right>") #'windmove-right)

  ;; s-[<>] to use `winner-mode'
  (exwm-input-set-key (kbd "s-<") #'winner-undo)
  (exwm-input-set-key (kbd "s->") #'winner-redo))

(use-package exwm
  :ensure t
  :init
  (defun ds/adjust-window-leading-edge (delta dir)
    (let ((otherwin (window-in-direction dir))
          (otherdelta (* -1 delta)))
      (if otherwin
          (adjust-window-trailing-edge otherwin otherdelta (equal dir 'left)))))

  (defun ds/adjust-window-trailing-edge (delta dir)
    (adjust-window-trailing-edge (selected-window) delta (equal dir 'right)))

  (defun ds/exwm-window-resize--get-delta (delta default)
    (abs (or delta default)))

  (defun ds/exwm-window-grow-above (delta)
    (interactive "P")
    (ds/adjust-window-leading-edge (ds/exwm-window-resize--get-delta delta 5) 'above))

  (defun ds/exwm-window-shrink-above (delta)
    (interactive "P")
    (ds/adjust-window-leading-edge (* -1 (ds/exwm-window-resize--get-delta delta 5)) 'above))

  (defun ds/exwm-window-grow-below (delta)
    (interactive "P")
    (ds/adjust-window-trailing-edge (ds/exwm-window-resize--get-delta delta 5) 'below))

  (defun ds/exwm-window-shrink-below (delta)
    (interactive "P")
    (ds/adjust-window-trailing-edge (* -1 (ds/exwm-window-resize--get-delta delta 5)) 'below))

  (defun ds/exwm-window-grow-left (delta)
    (interactive "P")
    (ds/adjust-window-leading-edge (ds/exwm-window-resize--get-delta delta 10) 'left))

  (defun ds/exwm-window-shrink-left (delta)
    (interactive "P")
    (ds/adjust-window-leading-edge (* -1 (ds/exwm-window-resize--get-delta delta 10)) 'left))

  (defun ds/exwm-window-grow-right (delta)
    (interactive "P")
    (ds/adjust-window-trailing-edge (ds/exwm-window-resize--get-delta delta 10) 'right))

  (defun ds/exwm-window-shrink-right (delta)
    (interactive "P")
    (ds/adjust-window-trailing-edge (* -1 (ds/exwm-window-resize--get-delta delta 10)) 'right))
  :config
  (exwm-input-set-key (kbd "<C-s-up>") #'ds/exwm-window-grow-above)
  (exwm-input-set-key (kbd "<C-M-s-up>") #'ds/exwm-window-shrink-above)

  (exwm-input-set-key (kbd "<C-s-down>") #'ds/exwm-window-grow-below)
  (exwm-input-set-key (kbd "<C-M-s-down>") #'ds/exwm-window-shrink-below)

  (exwm-input-set-key (kbd "<C-s-left>") #'ds/exwm-window-grow-left)
  (exwm-input-set-key (kbd "<C-M-s-left>") #'ds/exwm-window-shrink-left)

  (exwm-input-set-key (kbd "<C-s-right>") #'ds/exwm-window-grow-right)
  (exwm-input-set-key (kbd "<C-M-s-right>") #'ds/exwm-window-shrink-right)

  ;;resize to ratio
  (exwm-input-set-key (kbd "s-=") #'ds/set-window-ratio)

  (defun ds/exwm-to-16:9 ()
    (interactive)
    (ds/set-window-ratio nil 16 9 t))

  (exwm-input-set-key (kbd "C-s-=") #'ds/exwm-to-16:9))

(use-package exwm
  :ensure t
  :config
  (defun ds/exwm-list-x-windows ()
    "Get list if all EXWM managed X windows."
    (let ((names ()))
      (dolist (pair exwm--id-buffer-alist)
        (with-current-buffer (cdr pair)
          ;; (setq names (append names `(,(replace-regexp-in-string "^ " "" (buffer-name)))))))
          (setq names (append names `(,(buffer-name))))))
      names))

  (defun ds/exwm-switch-to-x-window (buffer-or-name)
    "Switch to EXWM managed X window BUFFER-OR-NAME."
    (interactive (list (completing-read "Select Window: " (ds/exwm-list-x-windows) nil t)))
    (exwm-workspace-switch-to-buffer buffer-or-name))

  (defun ds/exwm-bring-window-here (buffer-or-name)
    "Move an EXWM managed X window BUFFER-OR-NAME to the current workspace."
    (interactive (list (completing-read "Bring Window: " (ds/exwm-list-x-windows) nil t)))
    (with-current-buffer buffer-or-name
      (exwm-workspace-move-window exwm-workspace--current exwm--id)
      (switch-to-buffer (exwm--id->buffer exwm--id))))

  (exwm-input-set-key (kbd "s-d") #'ds/exwm-switch-to-x-window)

  (exwm-input-set-key (kbd "C-s-d") #'ds/exwm-bring-window-here)

  ;; alias the C-x o binding to s-o
  (exwm-input-set-key (kbd "s-o") #'ds/switch-window)

  ;; use C-s-o instead of C-u s-o for window swap
  (exwm-input-set-key (kbd "C-s-o") '(lambda () (interactive) (ds/switch-window t))))

(use-package exwm
  :ensure t
  :config
  (defun ds/exwm-quit ()
    "Close a window in EXWM.

If it is an X window, then kill the buffer.
If it is not an X window, delete the window unless it is the only one."
    (interactive)
    (if (equal major-mode 'exwm-mode)
        (kill-buffer))
    (if (> (length (window-list)) 1)
        (delete-window)))
  (exwm-input-set-key (kbd "C-s-q") #'ds/exwm-quit))

(use-package exwm
  :ensure t
  :config
  ;; popup eshell
  (ds/popup-thing ds/exwm-popup-shell "*Popup Shell*"
                  (let ((eshell-buffer-name "*Popup Shell*"))
                    (eshell t)))
  (exwm-input-set-key (kbd "s-m") #'ds/exwm-popup-shell)

  ;; rules for displaying the popup buffer
  (ds/popup-thing-display-settings "*Popup Shell*" top -1 0.4)

  ;; 's-return': Launch new eshell
  (exwm-input-set-key (kbd "<s-return>")
                      (lambda ()
                        (interactive)
                        (eshell t)))

  ;; 'C-s-return': Launch new Termite window
  (exwm-input-set-key (kbd "<C-s-return>")
                      (lambda ()
                        (interactive)
                        (start-process-shell-command "termite" nil "termite"))))

(use-package exwm
  :ensure t
  :config
  (ds/popup-thing ds/exwm-popup-telegram "TelegramDesktop"
                  (start-process-shell-command "telegram" nil "telegram-desktop"))

  (ds/popup-thing-display-settings "TelegramDesktop" right -1 135)

  (exwm-input-set-key (kbd "<s-f1>") #'ds/exwm-popup-telegram))

(use-package exwm
  :ensure t
  :config
  (ds/popup-thing ds/exwm-popup-mattermost "Mattermost"
                  (start-process-shell-command "mattermost" nil "mattermost-desktop"))

  (ds/popup-thing-display-settings "Mattermost" right 0 135)

  (exwm-input-set-key (kbd "<s-f2>") #'ds/exwm-popup-mattermost))

(use-package exwm
  :ensure t
  :config
  (ds/popup-thing ds/exwm-popup-pavucontrol "Pavucontrol"
                  (start-process-shell-command "pavucontrol" nil "pavucontrol"))

  (ds/popup-thing-display-settings "Pavucontrol" bottom 0 30)

  (exwm-input-set-key (kbd "<s-f3>") #'ds/exwm-popup-pavucontrol))

(use-package exwm
  :ensure t
  :config
  ;; popup eshell
  (ds/popup-thing ds/exwm-popup-gnus "*Group*" (gnus))
  (exwm-input-set-key (kbd "s-g") #'ds/exwm-popup-gnus))

(use-package exwm
  :ensure t
  :config
  ;; popup eshell
  (ds/popup-thing ds/exwm-popup-flycheck "*Flycheck errors*" (flycheck-list-errors))
  (ds/popup-thing-display-settings "*Flycheck errors" bottom 0 0.1)
  (exwm-input-set-key (kbd "s-e") #'ds/exwm-popup-flycheck))

(use-package exwm
  :ensure t
  :config
  (exwm-input-set-key (kbd "<XF86AudioRaiseVolume>")
                      (lambda ()
                        (interactive)
                        (start-process "volume-up" nil (executable-find "pulseaudio-ctl") "up")))

  (exwm-input-set-key (kbd "<XF86AudioLowerVolume>")
                      (lambda ()
                        (interactive)
                        (start-process "volume-down" nil (executable-find "pulseaudio-ctl") "down")))

  (exwm-input-set-key (kbd "<XF86AudioMute>")
                      (lambda ()
                        (interactive)
                        (start-process "volume-mute" nil (executable-find "pulseaudio-ctl") "mute"))))

(use-package exwm
  :ensure t
  :config
  (setq exwm-input-simulation-keys
   '(
     ;; movement
     ([?\C-b] . left)
     ([?\M-b] . C-left)
     ([?\C-f] . right)
     ([?\M-f] . C-right)
     ([?\C-p] . up)
     ([?\C-n] . down)
     ([?\C-a] . home)
     ([?\C-e] . end)
     ([?\M-v] . prior)
     ([?\C-v] . next)
     ([?\C-d] . delete)
     ([?\C-k] . (S-end ?\C-x))
     ;; cut/paste.
     ([?\C-w] . ?\C-x)
     ([?\M-w] . ?\C-c)
     ([?\C-y] . ?\C-v)
     ;; undo/redo
     ([?\C-/] . ?\C-z)
     ([?\C-?] . ?\C-\S-z)
     ;; search
     ([?\C-s] . ?\C-f))))

(use-package exwm
  :ensure t
  :config
  (defun ds/exwm-keyrules-termite ()
    (if (and exwm-class-name
             (string= exwm-class-name "Termite"))
        (exwm-input-set-local-simulation-keys
         '(
           ([?\C-b] . left)
           ([?\M-b] . [?\M-b])
           ([?\C-f] . right)
           ([?\M-f] . [?\M-f])
           ([?\C-p] . up)
           ([?\C-n] . down)
           ([?\C-a] . [?\C-a])
           ([?\C-e] . [?\C-e])
           ([?\C-d] . [?\C-d])
           ([?\C-w] . [?\C-\S-x])
           ([?\M-w] . [?\C-\S-c])
           ([?\C-y] . [?\C-\S-v])))))

  (add-hook 'exwm-manage-finish-hook #'ds/exwm-keyrules-termite))

(use-package exwm-randr
  :demand t
  :after exwm
  :init
  (defun ds/display-connected-p (name)
    "Test if display NAME is connected."
    (let* ((test-string (format "%s connected" name))
           (shell-cmd (format "xrandr | grep -o '^%s' | tr -d '\n'" test-string)))
      (equal test-string (shell-command-to-string shell-cmd))))

  (defun ds/list-displays ()
    "List all displays this machine can handle."
    (split-string
     (shell-command-to-string
      "xrandr | grep -Eo '^[A-Za-z0-9-]+ (dis)?connected' | awk '{print $1}' | tr '\n' ' '")))

  (defun ds/laptop-display-name ()
    "Get laptop internal display name ."
    (shell-command-to-string
     "xrandr | grep -Eo '^eDP[A-Za-z0-9-]+ connected' | awk '{print $1}' | tr -d '\n'"))

  (defun ds/laptop-external-display-name ()
    "Get laptop external display name ."
    (shell-command-to-string
     "xrandr | grep -Eo '^[^e][A-Za-z0-9-]+ connected' | awk '{print $1}' | tr -d '\n'"))

  (defun ds/restart-bar ()
    "Restart whatever bar is being used."
    (interactive)
    (start-process-shell-command
     "startpanel" nil (expand-file-name (concat user-emacs-directory "exwm/bin/start-bar"))))

  (defun ds/xrandr-other-displays-off (target)
    "Get a string to run off all displays except for the TARGET."
    (mapconcat
     (lambda (d)
       (concat "--output " d " --off"))
     (seq-filter
      (lambda (d)
        (not (string= d target)))
      (ds/list-displays))
     " "))

  (defun ds/connect-laptop-external ()
    "Connect the laptop to it's external display, no display on laptop screen"
    (interactive)
    (start-process-shell-command
     "xrandr" nil (concat "xrandr --output "
                          (ds/laptop-external-display-name)
                          " --primary --auto "
                          (ds/xrandr-other-displays-off (ds/laptop-external-display-name))))
    (ds/restart-bar))

  (defun ds/disconnect-laptop-external ()
    "Connect laptop display, no external display"
    (interactive)
    (start-process-shell-command
     "xrandr" nil (concat "xrandr --output "
                          (ds/laptop-display-name)
                          " --primary --auto "
                          (ds/xrandr-other-displays-off (ds/laptop-display-name))))
    (ds/restart-bar))

  (defun ds/exwm-auto-screens ()
    "Detect known display setups and set screens accordingly."
    (interactive)
    (let ((laptop-display (ds/display-connected-p (ds/laptop-display-name)))
          (laptop-display-external (ds/display-connected-p (ds/laptop-external-display-name))))
      ;; check for laptop external display
      (if laptop-display
          (if laptop-display-external
              (ds/connect-laptop-external)
            (ds/disconnect-laptop-external)))))

  :config
  (add-hook 'exwm-randr-screen-change-hook #'ds/powerline-set-height)
  (add-hook 'exwm-randr-screen-change-hook #'ds/exwm-auto-screens)
  (exwm-randr-enable))

(use-package exwm
  :ensure t
  :init
  :config
  (exwm-input-set-key (kbd "s-p") #'password-store-copy)
  (exwm-input-set-key (kbd "C-s-p") #'ds/password-store-get-otp))

(use-package exwm
  :ensure t
  :init
  (defun ds/exwm-refresh-notification-buffer (&rest _)
    (if (get-buffer-window (get-buffer "*notifications*"))
        (eosd-mode-create-or-update-buffer)))

  (defun ds/exwm-notification-autopop (&rest _)
    "Popup the notification buffer without taking focus from the current window."
    (let ((currentbuffer (buffer-name)))
      (if (equal currentbuffer "*notifications*")
          (ds/exwm-refresh-notification-buffer)
        (progn (ds/exwm-eosd)
               (with-current-buffer currentbuffer
                 (select-window (get-buffer-window (buffer-name)) t))))))
  ;; load eosd
  (add-to-list 'load-path "~/.emacs.d/eosd/")
  (require 'eosd)
  ;; customize notification faces
  (eval-after-load 'zenburn-theme
    (zenburn-with-color-variables
      (set-face-attribute 'eosd-heading-face nil :foreground zenburn-fg-1)
      (set-face-attribute 'eosd-title-face nil :foreground zenburn-green)
      (set-face-attribute 'eosd-datetime-face nil :foreground zenburn-blue)
      (set-face-attribute 'eosd-action-link-face nil :foreground zenburn-blue :background zenburn-bg+1 :box zenburn-blue :underline nil)
      (set-face-attribute 'eosd-delete-link-face nil :foreground zenburn-red :background zenburn-bg+1 :box zenburn-red :underline nil)
      (set-face-attribute 'eosd-text-mark-face nil :foreground zenburn-fg-1)))
  ;; start the notification service
  (eosd-start)
  :config
  ;; show notifications in side window
  (ds/popup-thing ds/exwm-eosd "*notifications*"
                  (eosd))
  (ds/popup-thing-display-settings "*notifications*" right 1)

  (exwm-input-set-key (kbd "s-n") #'ds/exwm-eosd)

  ;; auto refresh and auto popup notifications
  (add-function :after (symbol-function 'ds/exwm-eosd) #'ds/exwm-refresh-notification-buffer))

(use-package exwm
  :ensure t
  :init
  (defun ds/lock-screen (&rest _)
    (interactive)
    (start-process "" nil "slock"))
  :config
  (exwm-input-set-key (kbd "C-M-S-s-l") #'ds/lock-screen)
  (define-key global-map (kbd "C-x C-z") #'ds/lock-screen)
  (define-key global-map (kbd "C-z") #'ds/lock-screen))

(use-package exwm-systemtray
  :demand t
  :config
  (exwm-systemtray-enable))

(use-package exwm-cm
  :demand t
  :disabled
  :config
  (setq window-system-default-frame-alist '((x . ((alpha . 93)))))
  (setq exwm-cm-opacity 99)
  (exwm-cm-enable))

(use-package exwm
  :ensure t
  :disabled
  :config
  ;; enable pinentry
  (pinentry-start t)
  (setq pinentry-popup-prompt-window nil)
  ;; start exwm
  (exwm-enable))

(let ((local-conf (concat user-emacs-directory "local.el")))
      (if (file-exists-p local-conf)
          (load-file local-conf)))
