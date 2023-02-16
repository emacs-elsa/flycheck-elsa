;;; flycheck-elsa.el --- Flycheck for Elsa  -*- lexical-binding: t -*-

;; Copyright (C) 2018 Matúš Goljer

;; Author: Matúš Goljer <matus.goljer@gmail.com>
;; Maintainer: Matúš Goljer <matus.goljer@gmail.com>
;; Version: 1.0.0
;; Created: 23rd August 2018
;; Package-requires: ((emacs "25") (flycheck "0.14") (seq "2.0"))
;; Keywords: convenience
;; Homepage: https://github.com/emacs-elsa/flycheck-elsa

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Flycheck integration for Elsa.  See README.md

;;; Code:

(require 'flycheck)
(require 'cl-lib)
(require 'seq)

(defgroup flycheck-elsa nil
  "Flycheck integration for Elsa"
  :prefix "flycheck-elsa-"
  :group 'flycheck
  :link '(url-link :tag "Github" "https://github.com/emacs-elsa/flycheck-elsa"))

(defcustom flycheck-elsa-backend 'cask
  "Choose what backend to use to power it up.
The value can only be the symbol `cask' or `eask'.

If value is `cask', then Cask will be used as the backend to check for the
current file.  This means you must have a Cask-file presented in your project.

If value is `eask', the conditions are very similar to Cask. But instead, you
will need an Eask-file and not Cask-file."
  :group 'flycheck-elsa
  :type '(choice
          (const :tag "Cask" 'cask)
          (const :tag "Eask" 'eask)))

(defcustom flycheck-elsa-ignored-files-regexps '(
                                                 "\\`Cask\\'"
                                                 "\\`Eask\\'"
                                                 )
  "List of regular expressions matching files which should be ignored by Elsa."
  :group 'flycheck-elsa
  :type '(repeat regexp))

(defun flycheck-elsa--config-file ()
  "Return the target configuration filename by variable `flycheck-elsa-backend'."
  (cl-case flycheck-elsa-backend
    (`cask "Cask")
    (`eask "Eask")
    (t (user-error "Unknown Elsa backend: %s" flycheck-elsa-backend))))

(defun flycheck-elsa--locate-config-dir ()
  "Return dir located config file.  If missing, return nil."
  (when-let* ((filename (buffer-file-name))
              (config (flycheck-elsa--config-file))
              (file (locate-dominating-file filename config)))
    (file-name-directory file)))

(defun flycheck-elsa--elsa-dependency-p ()
  "Return non-nil if elsa listed in config file dependency."
  (let ((config-dir (flycheck-elsa--locate-config-dir))
        (config (flycheck-elsa--config-file)))
    (with-temp-buffer
      (insert-file-contents (expand-file-name config config-dir))
      (let* ((contents (read (format "(%s)" (buffer-string))))
             (deps (append
                    (mapcan
                     (lambda (elm)
                       (and (eq 'depends-on (car elm)) (list elm)))
                     contents)
                    (mapcan
                     (lambda (elm)
                       (and (eq 'development (car elm))
                            (mapcan
                             (lambda (elm)
                               (and (eq 'depends-on (car elm)) (list elm)))
                             (cdr elm))))
                     contents))))
        (and (delq 'nil (mapcar
                         (lambda (elm) (string= "elsa" (nth 1 elm))) deps))
             t)))))                     ; normarize return value

(defun flycheck-elsa--enable-p ()
  "Return non-nil if we can enable Elsa in current buffer.

We require that the project is managed by config file and that Elsa is
listed as a dependency."
  (when-let (config-dir (flycheck-elsa--locate-config-dir))
    (let ((default-directory config-dir))
      (and (buffer-file-name)
           (not (seq-find (lambda (f) (string-match-p f (buffer-file-name)))
                          flycheck-elsa-ignored-files-regexps))
           (flycheck-elsa--elsa-dependency-p)))))

(defun flycheck-elsa--working-directory (&rest _)
  "Return the working directory where the checker should run."
  (if (buffer-file-name)
      (flycheck-elsa--locate-config-dir)
    default-directory))

(defun flycheck-elsa-command ()
  "Return a list of strings for the command to execute and its arguments.
The result depends on the variable `flycheck-elsa-backend'."
  (cl-case flycheck-elsa-backend
    (`cask '("cask" "exec" "elsa"))
    (`eask '("eask" "exec" "elsa"))
    (t (user-error "Unknown Elsa backend: %s" flycheck-elsa-backend))))

(flycheck-define-checker emacs-lisp-elsa
  "An Emacs Lisp checker using Elsa."
  :command (;; flycheck forces us to pass a string as first argument:
            ;; https://github.com/flycheck/flycheck/issues/1515
            "emacs"
            (eval (cdr (flycheck-elsa-command)))
            source-inplace)
  :working-directory flycheck-elsa--working-directory
  :predicate flycheck-elsa--enable-p
  :error-filter flycheck-increment-error-columns
  :error-patterns
  ((error line-start (file-name) ":"  line ":" column ":error:" (message (one-or-more not-newline) (* "\n" (one-or-more " ") (one-or-more not-newline))))
   (warning line-start (file-name) ":" line ":" column ":warning:" (message (one-or-more not-newline) (* "\n" (one-or-more " ") (one-or-more not-newline))))
   (info line-start (file-name) ":" line ":" column ":notice:" (message (one-or-more not-newline) (* "\n" (one-or-more " ") (one-or-more not-newline)))))
  :modes (emacs-lisp-mode))

(defun flycheck-elsa--setup-executable ()
  "Configure `flycheck-emacs-lisp-elsa-executable'."
  (setq-local flycheck-emacs-lisp-elsa-executable
              (car (flycheck-elsa-command))))

;;;###autoload
(defun flycheck-elsa-setup ()
  "Setup Flycheck with Elsa."
  (interactive)
  (add-to-list 'flycheck-checkers 'emacs-lisp-elsa)
  (add-hook 'flycheck-before-syntax-check-hook #'flycheck-elsa--setup-executable))

(provide 'flycheck-elsa)
;;; flycheck-elsa.el ends here
