;;; flycheck-elsa.el --- Flycheck for Elsa. -*- lexical-binding: t -*-

;; Copyright (C) 2018 Matúš Goljer

;; Author: Matúš Goljer <matus.goljer@gmail.com>
;; Maintainer: Matúš Goljer <matus.goljer@gmail.com>
;; Version: 1.0.0
;; Created: 23rd August 2018
;; Package-requires: ((emacs "25") (seq "2.0") (cask "0.8.4"))
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
(require 'cask)
(require 'seq)

(defgroup flycheck-elsa nil
  "Flycheck integration for Elsa"
  :prefix "flycheck-elsa-"
  :group 'flycheck
  :link '(url-link :tag "Github" "https://github.com/emacs-elsa/flycheck-elsa"))

(defcustom flycheck-elsa-ignored-files-regexps '(
                                                 "\\`Cask\\'"
                                                 )
  "List of regular expressions matching files which should be ignored by Elsa."
  :group 'flycheck-elsa
  :type '(repeat regexp))

(defcustom flycheck-elsa-command 'cask
  "List of strings for the command to execute with its arguments.
The value can also be the symbol `cask' or `host'.

If value is `cask', then Cask will be used to start Elsa on the
current file.  This means that the file's project must have a Cask
configuration file including Elsa as a development dependency.

If value is `host', then Elsa and its dependencies must be
installed and in Emacs' `load-path' as they will be used by
flycheck.

If value is a list of strings, it will be passed unchanged as the
`:command' argument to `flycheck-define-command-checker'."
  :group 'flycheck-elsa
  :type '(choice
          (const :tag "Cask" 'cask)
          (const :tag "Emacs" 'host)
          (repeat 'string)))

(defun flycheck-elsa--filename-ignored-p (filename)
  "Return non-nil if FILENAME is matched by one of `flycheck-elsa-ignored-files-regexps'."
  (seq-find
   (lambda (regexp) (string-match-p regexp filename))
   flycheck-elsa-ignored-files-regexps))

(defun flycheck-elsa--enable-p ()
  "Return non-nil if we can enable Elsa in current buffer."
  (if (flycheck-elsa-cask-p)
      (when (and (buffer-file-name)
                 (not (flycheck-elsa--filename-ignored-p (buffer-file-name))))
        (when-let ((cask-file (locate-dominating-file (buffer-file-name) "Cask")))
          (let ((bundle (cask-initialize (file-name-directory cask-file))))
            (cask-find-dependency bundle 'elsa))))
    (if (buffer-file-name)
        (not (flycheck-elsa--filename-ignored-p (buffer-file-name)))
      t)))

(defun flycheck-elsa--working-directory (&rest _)
  "Return the working directory where the checker should run."
  (if (buffer-file-name)
      (if (flycheck-elsa-cask-p)
          (when-let (file (locate-dominating-file (buffer-file-name) "Cask"))
            (file-name-directory file))
        (file-name-directory (cdr (project-current))))
    default-directory))

(defun flycheck-elsa--cask-command ()
  "Return a list of strings to start Elsa within a Cask project."
  '("cask" "exec" "elsa"))

(defun flycheck-elsa--elsa-dependency-directory (library-name)
  "Return the directory containing LIBRARY-NAME."
  (file-name-directory (find-library-name library-name)))

(defun flycheck-elsa--elsa-dependency-directories ()
  "Return a list of directories where Elsa and its dependencies are installed."
  (let ((directories (mapcar
                      #'flycheck-elsa--elsa-dependency-directory
                      '("elsa" "dash" "trinary" "f" "s" "flycheck"))))
    (seq-uniq directories)))

(defun flycheck-elsa--elsa-command ()
  "Return the path to elsa executable file."
  (expand-file-name
   "elsa"
   (expand-file-name "bin" (flycheck-elsa--elsa-dependency-directory "elsa"))))

(defun flycheck-elsa--host-command ()
  "Return a list of strings to start Emacs with Elsa.
Elsa and its dependencies are expected to be in `load-path'."
  `(,(flycheck-elsa--elsa-command)
    ,@(mapcan
       (lambda (directory) (list "--directory" directory))
       (flycheck-elsa--elsa-dependency-directories))))

(defun flycheck-elsa-command ()
  "Return a list of strings for the command to execute and its arguments.
The result depends on the variable `flycheck-elsa-command'."
  (cond
   ((eq flycheck-elsa-command 'cask) (flycheck-elsa--cask-command))
   ((eq flycheck-elsa-command 'host) (flycheck-elsa--host-command))
   (t flycheck-elsa-command)))

(defun flycheck-elsa-cask-p ()
  "Return non-nil if the project should be checked through Cask."
  (eq flycheck-elsa-command 'cask))

(flycheck-define-checker emacs-lisp-elsa
  "An Emacs Lisp checker using Elsa"
  :command (;; flycheck forces us to pass a string as first argument:
            ;; https://github.com/flycheck/flycheck/issues/1515
            "emacs"
            (eval (cdr (flycheck-elsa-command)))
            source-inplace)
  :working-directory flycheck-elsa--working-directory
  :predicate flycheck-elsa--enable-p
  :error-filter flycheck-increment-error-columns
  :error-patterns
  ((error line-start line ":" column ":error:" (message))
   (warning line-start line ":" column ":warning:" (message))
   (info line-start line ":" column ":notice:" (message)))
  :modes (emacs-lisp-mode))

;; flycheck forces us to pass a string as first argument:
;; https://github.com/flycheck/flycheck/issues/1515
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
