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

(defun flycheck-elsa--enable-p ()
  "Return non-nil if we can enable Elsa in current buffer.

We require that the project is managed by Cask and that Elsa is
listed as a dependency."
  (when (and (buffer-file-name)
             (not (seq-find (lambda (f) (string-match-p f (buffer-file-name)))
                            flycheck-elsa-ignored-files-regexps)))
    (when-let ((cask-file (locate-dominating-file (buffer-file-name) "Cask")))
      (let ((bundle (cask-initialize (file-name-directory cask-file))))
        (cask-find-dependency bundle 'elsa)))))

(defun flycheck-elsa--working-directory (&rest _)
  "Return the working directory where the checker should run."
  (if (buffer-file-name)
      (file-name-directory (locate-dominating-file (buffer-file-name) "Cask"))
    default-directory))

(flycheck-define-checker emacs-lisp-elsa
  "Checker for PHPStan"
  :command ("cask" "exec" "elsa" source)
  :working-directory flycheck-elsa--working-directory
  :predicate flycheck-elsa--enable-p
  :error-filter flycheck-increment-error-columns
  :error-patterns
  ((error line-start line ":" column ":error:" (message))
   (warning line-start line ":" column ":warning:" (message))
   (info line-start line ":" column ":notice:" (message)))
  :modes (emacs-lisp-mode))

;;;###autoload
(defun flycheck-elsa-setup ()
  "Setup Flycheck with Elsa."
  (interactive)
  (add-to-list 'flycheck-checkers 'emacs-lisp-elsa))

(provide 'flycheck-elsa)
;;; flycheck-elsa.el ends here
