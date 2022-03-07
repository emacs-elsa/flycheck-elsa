[![MELPA](https://melpa.org/packages/flycheck-elsa-badge.svg)](https://melpa.org/#/flycheck-elsa)

# flycheck-elsa - Flycheck for Elsa

Integration of [Elsa](https://github.com/emacs-elsa/Elsa) into [Flycheck](https://github.com/flycheck/flycheck).

# Elsa in Cask projects

The recommended way to use Elsa is with [Cask](https://github.com/cask/cask).

## Installation

Install `flycheck-elsa` from [MELPA](http://melpa.org/) or [MELPA
Stable](http://stable.melpa.org/) and add the following to your
`init.el`:

``` emacs-lisp
(add-hook 'emacs-lisp-mode-hook #'flycheck-elsa-setup)
```

We require that `cask` executable is usable from Emacs.  You can test
this by evaluating `(executable-find "cask")`.  If this returns `nil`,
you need to add your cask directory to `exec-path`.  With the default
Cask installation evaluating the following snippet should be enough:

``` emacs-lisp
(push (format "/home/%s/.cask/bin/" (user-login-name)) exec-path)
```

You can also use the amazing
[exec-path-from-shell](https://github.com/purcell/exec-path-from-shell)
to initialize your `exec-path` from your shell's `$PATH`.

## Usage

Just use Flycheck as usual in your [Cask](https://github.com/cask/cask) projects.
