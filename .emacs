
(global-display-line-numbers-mode)
(setq display-line-numbers-type 'relative)

(require 'package)

;; Nice macro for updating lists in place.
(defmacro append-to-list (target suffix)
  "Append SUFFIX to TARGET in place."
  `(setq ,target (append ,target ,suffix)))

;; Set up emacs package archives with 'package
(append-to-list package-archives
                '(("melpa" . "http://melpa.org/packages/") ;; Main package archive
                  ("melpa-stable" . "http://stable.melpa.org/packages/") ;; Some packages might only do stable releases?
                  ("org-elpa" . "https://orgmode.org/elpa/"))) ;; Org packages, I don't use org but seems like a harmless default

(package-initialize)

;; Ensure use-package is present. From here on out, all packages are loaded
;; with use-package, a macro for importing and installing packages. Also, refresh the package archive on load so we can pull the latest packages.
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq
 use-package-always-ensure t ;; Makes sure to download new packages if they aren't already downloaded
 use-package-verbose t) ;; Package install logging. Packages break, it's nice to know why.

;; Slurp environment variables from the shell.
;; a.k.a. The Most Asked Question On r/emacs
(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("0325a6b5eea7e5febae709dab35ec8648908af12cf2d2b569bedc8da0a3a81c1" default))
 '(package-selected-packages '(doom-themes exec-path-from-shell)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(use-package doom-themes
  :init
  (load-theme 'doom-one))


;; Any Customize-based settings should live in custom.el, not here.
(setq custom-file "~/.emacs.d/custom.el") ;; Without this emacs will dump generated custom settings in this file. No bueno.
(load custom-file 'noerror)

;;; OS specific config
(defconst *is-a-mac* (eq system-type 'darwin))
(defconst *is-a-linux* (eq system-type 'gnu/linux))

;; Emacs feels like it's developed with linux in mind, here are some mac UX improvments
(when *is-a-mac*
  (setq mac-command-modifier 'meta)
  (setq mac-option-modifier 'none)
  (setq default-input-method "MacOSX"))

;; Some linux love, too
(when *is-a-linux*
  (setq x-super-keysym 'meta))

;; Fullscreen by default, as early as possible. This tiny window is not enough
(add-to-list 'default-frame-alist '(fullscreen . maximized))


;; Make M-x and other mini-buffers sortable, filterable
(use-package ivy
  :init
  (ivy-mode 1)
  (setq ivy-height 15
        ivy-use-virtual-buffers t
        ivy-use-selectable-prompt t))

(use-package counsel
  :after ivy
  :init
  (counsel-mode 1)
  :bind (:map ivy-minibuffer-map))


;; We need something to manage the various projects we work on
;; and for common functionality like project-wide searching, fuzzy file finding etc.
(use-package projectile
  :init
  (projectile-mode t) ;; Enable this immediately
  :config
  (setq projectile-enable-caching t ;; Much better performance on large projects
        projectile-completion-system 'ivy)) ;; Ideally the minibuffer should aways look similar

;; Counsel and projectile should work together.
(use-package counsel-projectile
  :init
  (counsel-projectile-mode))



;; Company is the best Emacs completion system.
(use-package company
  :bind (("C-." . company-complete))
  :custom
  (company-idle-delay 0) ;; I always want completion, give it to me asap
  (company-dabbrev-downcase nil "Don't downcase returned candidates.")
  (company-show-numbers t "Numbers are helpful.")
  (company-tooltip-limit 10 "The more the merrier.")
  :config
  (global-company-mode) ;; We want completion everywhere

  ;; use numbers 0-9 to select company completion candidates
  (let ((map company-active-map))
    (mapc (lambda (x) (define-key map (format "%d" x)
                        `(lambda () (interactive) (company-complete-number ,x))))
          (number-sequence 0 9))))

;; For terraform HCL auto completion
(use-package company
  :ensure t
  :hook (terraform-mode . company-mode))


;; Flycheck is the newer version of flymake and is needed to make lsp-mode not freak out.
(use-package flycheck
  :config
  (add-hook 'prog-mode-hook 'flycheck-mode) ;; always lint my code
  (add-hook 'after-init-hook #'global-flycheck-mode))

;; Package for interacting with language servers
(use-package lsp-mode
  :commands lsp
  :config
  (setq lsp-prefer-flymake nil ;; Flymake is outdated
        lsp-headerline-breadcrumb-mode nil)) ;; I don't like the symbols on the header a-la-vscode, remove this

(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :hook ((terraform-mode . lsp-deferred))
  :config
  (setq lsp-terraform-ls-prefill-required-fields t))


(use-package lsp-mode
  :ensure t
  :commands lsp
  :config
  (setq lsp-terraform-ls-bin "terraform-ls"))

;;for terraform HCL
(use-package terraform-mode
  :ensure t
  :hook ((terraform-mode . terraform-format-on-save-mode)) ; Automatically format on save
  :config
  )


(use-package lsp-ui
  :ensure t
  :commands lsp-ui-mode
  :hook (lsp-mode . lsp-ui-mode)
  :config
  (setq lsp-ui-sideline-enable t
        lsp-ui-sideline-show-hover t
        lsp-ui-doc-enable t))

(use-package npm)

;; go LSP
(use-package go-mode
  :ensure t)

(add-hook 'go-mode-hook 'lsp-deferred)
(add-hook 'go-mode-hook 'subword-mode)
(add-hook 'before-save-hook 'gofmt-before-save)

(add-hook 'go-mode-hook (lambda ()
                          (setq tab-width 4)
                          (flycheck-add-next-checker 'lsp 'go-vet)
                          (flycheck-add-next-checker 'lsp 'go-staticcheck)))


(use-package vterm
  :ensure t)

;; (use-package vterm
;;   :ensure t
;;   :config
;;   ;; Bindings inside vterm
;;   (define-key vterm-mode-map (kbd "C-x b") #'switch-to-buffer)
;;   (define-key vterm-mode-map (kbd "C-x o") #'other-window))

(add-to-list 'load-path "/home/isay/.emacs.d/elpa/dockerfile-mode/dockerfile-mode.el")
(require 'dockerfile-mode)
(add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-mode))



(defun google-search (query)
  "Search Google for QUERY."
  (interactive "sGoogle: ")
  (browse-url (concat "https://www.google.com/search?q=" (url-hexify-string query))))
(global-set-key (kbd "C-c g") 'google-search)

;; (use-package engine-mode
;;   :ensure t
;;   :config
;;   (engine-mode t)
;;   (defengine google
;;     "https://www.google.com/search?q=%s"
;;     :keybinding "g"))


(global-set-key (kbd "C-c <") 'indent-rigidly-left)
(global-set-key (kbd "C-c >") 'indent-rigidly-right)

(global-font-lock-mode 1)

