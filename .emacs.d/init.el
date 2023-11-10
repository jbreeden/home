;; This file should stand alone.

;; To get emacs itself, with all the good stuff, on MacOS:
;;
;; brew install emacs-plus@30 --with-native-comp

(setq native-comp-always-compile t)

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless (load "use-package" 'noerr)
  (package-refresh-contents)
  (package-install 'use-package)
  (load "use-package" 'noerr))

;; --- Emacs options --------------------------------------------------------

(setq-default dired-listing-switches "-alh") ; Use human readable file sizes
(setq-default scroll-step 1)
(setq-default hscroll-step 1)
(setq-default completion-ignore-case t)
(setq-default confirm-kill-emacs (quote y-or-n-p))
(setq-default enable-recursive-minibuffers t)
(setq-default inhibit-startup-screen t)
(setq-default mouse-scroll-delay 0)
(setq-default mouse-wheel-scroll-amount '(1))
(setq-default ns-command-modifier (quote meta))
(setq-default read-buffer-completion-ignore-case t)
(setq-default read-file-name-completion-ignore-case t)
(setq-default repeat-on-final-keystroke t)
(setq-default truncate-lines t)
(setq-default vc-follow-symlinks t)
(setq-default wdired-allow-to-change-permissions t)
(setq-default indent-tabs-mode nil)
(setq-default auto-save-default nil) ; no littering
(setq-default make-backup-files nil) ; no littering
(setq-default create-lockfiles nil) ; no littering
(setq-default require-final-newline t)
(setq-default eldoc-echo-area-prefer-doc-buffer t)
(setq-default use-short-answers t)

(progn ; Keep "custom" variables separate from this init file
  (setq-default custom-file "~/.emacs.d/custom.el")
  (when (file-exists-p custom-file)
    (load custom-file)))

;; Performance stuff, especially things suggested by
;; https://emacs-lsp.github.io/lsp-mode/page/performance/
(setq gc-cons-threshold (* 100 (expt 2 20))) ; 100MB
(setq read-process-output-max (expt 2 20)) ; 1MB

(put 'dired-find-alternate-file 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'scroll-left 'disabled nil)
(put 'scroll-right 'disabled nil)
(put 'upcase-region 'disabled nil)

;; --- Builtin Modes ------------------------------------------------

(tool-bar-mode -1)
(menu-bar-mode -1)
(savehist-mode 1)   ;; Save minibuffer history between sessions
(show-paren-mode 1)
(xterm-mouse-mode 1)
(global-display-line-numbers-mode 1)
(when (functionp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode))

(setq display-buffer-alist
      '(("*vterm" display-buffer-in-side-window (direction . left))
        ("*deadgrep" display-buffer-split-with-current (direction . left))))

;; -- Unset the above --
;; (setq display-buffer-alist nil)

(defun display-buffer-split-with-current (buffer alist)
  (let ((current (current-buffer)))
    (delete-other-windows)
    (display-buffer-in-direction buffer alist)))

;; --- Key bindings -------------------------------------------------

(bind-key* "M-o" 'other-window)
(bind-key* "C-c ." 'bury-buffer)
(bind-key* "C-c ," 'unbury-buffer)
(bind-key* "C-c b" 'switch-to-buffer)
(bind-key* "C-c C-g" 'reload-major-mode)

; M-{n,p} find the "next error" (works with ripgrep/deadgrep results
(bind-key "M-n" 'next-error)
(bind-key "M-p" 'previous-error)
; M-{N,P} go to the next flymake error (works for LSP errors)
(bind-key* "M-N" 'flymake-goto-next-error)
(bind-key* "M-P" 'flymake-goto-prev-error)

;; --- Commands -----------------------------------------------------

(defun sudoedit (filename)
  (interactive "fsudoedit file: ")
  (message filename)
  (find-file (concat "/sudo::" (file-truename filename))))

(defun reload-major-mode ()
  (interactive)
  (funcall major-mode))

;; --- Shell stuff --------------------------------------------------

;; Make sure shell commands use my bashrc
(setenv "BASH_ENV" (concat (getenv "HOME") "/.bashrc"))

;; Setup default shell
(if (file-exists-p "/usr/local/bin/bash")
    (setq-default shell-file-name "/usr/local/bin/bash")
  (setq-default shell-file-name "bash"))

(setq-default explicit-shell-file-name shell-file-name)

;; ---- Packages --------------------------------------------

;; -- Builtins --

(use-package cc-vars
  :config
  (setq-default c-basic-offset 2))

(use-package hl-line
  :defer 2
  :config
  (global-hl-line-mode))

(use-package smerge-mode
  :defer t
  :config
  (bind-key (kbd "C-c C-c") 'smerge-keep-current smerge-mode-map))

(use-package recentf
  :config
  (recentf-mode))

(use-package project
  :config
  (defvar project-root-files '("go.mod" "package.json"))
  (defun project-try-go-mod (dir)
    (when-let ((root
                (cond
                 ((file-exists-p "go.mod") default-directory)
                 (t (locate-dominating-file default-directory "go.mod")))))
      (cons 'transient (file-truename root))))

  (add-to-list 'project-find-functions 'project-try-go-mod))

(use-package ansi-color
    :hook (compilation-filter . ansi-color-compilation-filter))


(use-package treesit
  :config
  (setq-default treesit-font-lock-level 4))


;; Automatically handle the treesit configuration, and enabling treesit modes.
;; See here for manual setup instructions:
;;   https://www.masteringemacs.org/article/how-to-get-started-tree-sitter#:~:text=The%20command%20M%2Dx%20treesit%2Dinstall,to%20find%20the%20language%20grammars.
(use-package treesit-auto
  :ensure
  :config
  (global-treesit-auto-mode))

;; (mapc #'treesit-install-language-grammar (mapcar #'car treesit-language-source-alist))

(use-package winner
  :init
  (winner-mode)
  ;; C-c <left> will undo window layout chages
  ;; C-c <right> will undo window layout chages
  :bind (("C-c -" . winner-undo)
         ("C-c =" . winner-redo)))

;; -- External ------------------------------------------------

(use-package fasd
  :ensure t
  :bind* (("C-c f" . fasd-find-file))
  :config
  (global-fasd-mode 1))

(use-package exec-path-from-shell
  :ensure t
  :init
  (setq-default exec-path-from-shell-shell-name "zsh")
  :config (exec-path-from-shell-initialize))

(use-package spacemacs-theme
  :defer t
  :ensure t)

(use-package solarized-theme
  :defer t
  :ensure t)

(use-package atom-one-dark-theme
  :defer t
  :ensure t)

(load-theme 'atom-one-dark 'noconfirm)
(if window-system
    (set-face-attribute 'default nil :height 140)
  (set-face-background 'default "black"))

(use-package windmove ; Shift+Arrow moves point to adjacent windows
  :config
  (windmove-default-keybindings))

(use-package buffer-move ; Ctrl+Shift+Arrow moves buffer to adjacent windows
  :ensure t
  :config
  (setq buffer-move-behavior 'move)
  :bind (("<C-S-left>" . 'buf-move-left)
         ("<C-S-right>" . 'buf-move-right)
         ("<C-S-up>" . 'buf-move-up)
         ("<C-S-down>" . 'buf-move-down)))

(use-package which-key
  :ensure t
  :init
  (setq-default which-key-idle-delay 0.3)
  :config
  (which-key-mode))

(use-package selectrum
  :ensure t
  :config
  (selectrum-mode))

(use-package prescient
  :ensure t
  :config
  (prescient-persist-mode +1))

(use-package selectrum-prescient
  :ensure t
  :config
  (selectrum-prescient-mode +1))

(use-package deadgrep
  :ensure t
  :config

  (setq deadgrep-display-buffer-function 'display-buffer)
  (defun my/deadgrep-default-directory (search-term)
    (interactive (list (deadgrep--read-search-term)))
    (deadgrep search-term default-directory))

  :bind* (("C-c / ." . my/deadgrep-default-directory)
          ("C-c / /" . deadgrep)))

(use-package ws-butler
  :ensure t
  :hook (prog-mode . ws-butler-mode))

(use-package hungry-delete
  :ensure t
  :config
  (setq-default hungry-delete-join-reluctantly t))

(use-package move-text
  :ensure t
  :config
  (move-text-default-bindings))

(use-package string-inflection
  :defer 2
  :ensure t
  :bind (("C-c s _" . string-inflection-underscore)
         ("C-c s -" . string-inflection-kebab-case)
         ("C-c s C" . string-inflection-camelcase)
         ("C-c s c" . string-inflection-lower-camelcase)
         ("C-c s U" . string-inflection-upcase)))

(use-package define-word
  :ensure t
  :commands (define-word define-word-at-point))

(use-package company
  :ensure t
  :bind* (("C-c TAB" . company-complete))
  :config
  (global-company-mode)
  (setq-default company-async-timeout 6))

(use-package magit
  :defer 2
  :ensure t
  :bind (("C-c g s" . magit-status)
         ("C-c g f" . my-magit-find-file-in-worktree)
         ("C-c g g" . magit-file-dispatch))
  :config
  (progn
    (setq-default magit-display-buffer-function
                  'magit-display-buffer-same-window-except-diff-v1)

    (defun git ()
      (interactive)
      (call-interactively 'magit-git-command-topdir))

    (defun my-magit-find-file-in-worktree (file)
      (interactive (list
                    (let ((default-directory (magit-toplevel)))
                      (magit-read-file "Find file"))))
      (find-file (concat (magit-toplevel) file)))))

(use-package yaml-mode
  :ensure t)

(use-package go-mode
  :ensure t
  :init

  (setq gofmt-command "goimports")
  (add-hook 'before-save-hook 'gofmt-before-save) ; todo: Not for every mode?

  (defun goimports ()
    (interactive)
    (let ((gofmt-command "goimports"))
      (gofmt)))

  :hook (go-mode . (lambda()
                     (interactive)
                     (setq-local tab-width 4))))

(use-package cc-mode
  :config
  (setq java-ts-mode-indent-offset 2))

(use-package js
  ;; :init
  :mode ("\\.\\([jt]sx?\\)\\'" . tsx-ts-mode)
  :bind* (("M-." . 'xref-find-definitions))
  :config
  (setq js-indent-level 2))

;; Auto formatting for all the things
(use-package apheleia
  :ensure t
  :config
  (apheleia-global-mode +1)
  (setq apheleia-mode-alist
        '((php-mode . phpcs)
          (json-mode . prettier-json)
          (beancount-mode . bean-format)
          (cc-mode . clang-format)
          (c-mode . clang-format)
          (c++-mode . clang-format)
          (caml-mode . ocamlformat)
          (common-lisp-mode . lisp-indent)
          (css-mode . prettier-css)
          (dart-mode . dart-format)
          (elixir-mode . mix-format)
          (elm-mode . elm-format)
          (fish-mode . fish-indent)
          (go-mode . gofmt)
          (graphql-mode . prettier-graphql)
          (haskell-mode . brittany)
          (html-mode . prettier-html)
          (java-mode . google-java-format)
          (js3-mode . prettier-javascript)
          ; Prefer vanilla prettier over *-javascript to infer syntax from filename
          (js-mode . prettier)
          (js-ts-mode . prettier)
          (typescript-ts-mode . prettier)
          (tsx-ts-mode . prettier)
          (js-mode . prettier)
          (kotlin-mode . ktlint)
          (latex-mode . latexindent)
          (LaTeX-mode . latexindent)
          (lua-mode . stylua)
          (lisp-mode . lisp-indent)
          (nix-mode . nixfmt)
          (python-mode . black)
          (ruby-mode . prettier-ruby)
          (rustic-mode . rustfmt)
          (rust-mode . rustfmt)
          (scss-mode . prettier-scss)
          (sh-mode . shfmt)
          (terraform-mode . terraform)
          (TeX-latex-mode . latexindent)
          (TeX-mode . latexindent)
          (tuareg-mode . ocamlformat)
          ; Prefer vanilla prettier over *-typescript to infer syntax from filename
          (typescript-mode . prettier)
          (web-mode . prettier)
          (yaml-mode . prettier-yaml))))

(use-package eslint-fix
  :ensure t
  :commands (eslint-fix))

(use-package markdown-mode
  :ensure t)

(use-package terraform-mode
  :ensure t)

(use-package pipenv
  :ensure t
  :defer 1)

(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))

(use-package yasnippet
  :ensure t)

(use-package yasnippet-snippets
  :ensure t)

(use-package eglot
  ;; :ensure t
  :hook ((go-mode js-mode python-mode) . eglot-ensure)
  :bind* (("C-c a" . eglot-code-actions))
  :config
  (setq eglot-confirm-server-initiated-edits nil)
  (add-to-list 'eglot-server-programs '(terraform-mode "terraform-lsp")))


(use-package eglot-java
  :ensure t
  :hook (java-mode . eglot-java-init))

(use-package mermaid-mode
  :defer
  :ensure t
  :mode ("\\.mmd\\'" . mermaid-mode))

(use-package vterm
  :defer
  :ensure t
  :config
  (setq vterm-shell "bash"))

(use-package expand-region
  :defer
  :ensure t
  :bind (("C-=" . er/expand-region)
         ("C--" . er/contract-region)))

(use-package git-link
  :defer 4
  :ensure t)

(use-package multi-vterm
  :ensure t
  :bind (("C-c t t" . multi-vterm)
         ("C-c t d" . multi-vterm-dedicated-toggle)
         ("C-c t /" . multi-vterm-project)
         ("C-c t n" . multi-vterm-next)
         ("C-c t p" . multi-vterm-next)))

(use-package fzf
  :ensure t)

(defun my-vterm-toggle ()
  (interactive)
  (vterm-toggle)
  (rename-buffer (concat "*" (file-name-base (project-root (project-current))) "*")))

(use-package tuareg
  :defer
  :ensure t)

(use-package merlin
  :defer
  :ensure t)

(use-package jsdoc
  :defer
  :ensure t)

(use-package rust-mode
  :defer
  :ensure t)

;; --- Decodable stuff --------------------------------------------------------

(defun dj (worktree)
  (interactive (list (read-file-name "worktree: " "~/decodable/repos/decodable.d/")))
  (magit-status worktree))

(defun de-worktree (branch-name)
  (interactive (list (read-string "branch name: ")))
  (magit-status (string-trim (shell-command-to-string (format "de-worktree %s 2> /dev/null" (shell-quote-argument branch-name))))))

(put 'downcase-region 'disabled nil)
