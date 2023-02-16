[![MELPA](https://melpa.org/packages/flycheck-elsa-badge.svg)](https://melpa.org/#/flycheck-elsa)
[![CI](https://github.com/emacs-elsa/flycheck-elsa/actions/workflows/test.yml/badge.svg)](https://github.com/emacs-elsa/flycheck-elsa/actions/workflows/test.yml)

# flycheck-elsa - Flycheck for Elsa

Integration of [Elsa](https://github.com/emacs-elsa/Elsa) into [Flycheck](https://github.com/flycheck/flycheck).

## Installation

Install `flycheck-elsa` from [MELPA](http://melpa.org/) or [MELPA
Stable](http://stable.melpa.org/) and add the following to your
`init.el`:

``` emacs-lisp
(add-hook 'emacs-lisp-mode-hook #'flycheck-elsa-setup)
```

## How do I use this?

The recommended way to use Elsa is with [Eask][Eask] or [Cask][Cask].

```emacs-lisp
(setq flycheck-elsa-backend 'cask)  ; or 'eask
```

### Eask

This method uses [Eask][Eask] and installs Elsa from [MELPA][MELPA].

1. Make sure you have [Eask][Eask] installed and presented in your PATH environment.
2. You need an Eask-file in your project, you can create it via `eask init` command
3. Add `(depends-on "elsa")` to your Eask-file
4. Run `eask install-deps`

You are ready to go! Open an elisp file and `M-x flycheck-mode`!

### Cask

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

[Cask]: https://github.com/cask/cask
[Eask]: https://github.com/emacs-eask/cli
[MELPA]: https://melpa.org
