kfg: An extensible configuration system for emacs
=================================================

`kfg` is a configuration system for emacs. The basic premise of `kfg`
is that you have a set of *modules* which define a set of package
requirements (i.e. packages that need to be installed for that module)
and configuration code (i.e. code that is run when emacs starts up.)
Modules can be defined independently and can be installed simply by
copying a few files into a directory.

Typically a `kfg` configuration will be stored in a single directory
which we'll refer to as the *root* directory. The root directory can
be in `~/.emacs.d`, though it doesn't need to be. A common location
for the `kfg` root be `~/.emacs.d/kfg`, and this directory would
contain all of the rest of the module configuration information.

The root directory must contain two subdirectories, `elisp` and
`modules`. The `elisp` directory is a sort of dumping ground for
miscellaneous emacs lisp files, and this directory is added to your
emacs load path by `kfg`. You don't need to put anything in `elisp`,
but it can be convenient, for example, for storing emacs lisp code
which hasn't (yet) been bundled into a package.

The `modules` directory is the more interesting of the two
subdirectories. You use `modules` be adding directories to it for each
module that you want to define, and each of these module directories
has a specific structure that tells `kfg` about its dependencies and
configuration code. First, a module directory must contain `init.el`
which tells `kfg` about the module's dependencies and whether the
module is actually enabled (sometimes it's convenient to disable a
module without actually deleting it from the filesystem.) Second, it
must contains a `config.el` file which contains the emacs lisp code to
run to configure that module. Note that the configuration code is only
executed when a module is enabled.

Finally, once a configuration has been defined, you use the function
`(kfg-initialize <root directory>)` to read and process the
configuration. This is often the only `kfg` function with which you
need to interact.

Quickstart
==========

Let's see how that looks in practical terms. In this example the root
directory is `~/.emacs.d/kfg`. We'll define a single module, `ido`,
which contains configuration for the standard `ido` package. The
directory structure looks like this:

    .emacs.d/kfg
    ├── elisp
    │   └── my_utilities.el
    └── modules
        └── ido
            ├── config.el
            └── init.el

To "execute" this configuration you would execute the following code
from e.g. your `.emacs`:

    (require 'kfg)
    (kfg-initialize "~/.emacs.d/kfg")

After this call, the `elisp` directory will on the emacs *load path*,
so any emacs lisp files - like `my_utilities.el` in the example - can
be used. `kfg` doesn't make any assumptions about or place any
constraints on what goes in the `elisp` directory, and it's entirely
for your own convenience.

All subdirectories of `modules` are considered *modules* by `kfg`. In
this case, we've defined a single module, `ido`, which we'll use to
configure the use of IDO in emacs. The first file we need to look at
in the `ido` directory is `init.el`:

  '((:enabled . t)
    (:packages ido-vertical-mode))

The structure of a module's `init.el` is a list with two elements. The
first element has the key `:enabled` and should map to either `t` or
`nil` to indicate if he module is enabled or not, respectively. If a
module is not enabled (i.e. if `init.el` contains `(:enabled . nil)`)
then the module is not processed any further.

The second entry in the `init.el` list is a list starting with the
keywords `:packages`. All elements in the list after `:packages` are
treated as package dependencies for the module and will be installed
by `kfg` if needed. So in this example we've said that our `ido`
module depends on the `ido-vertical-mode` package. Note that this only
expresses a dependency; `kfg` will not automatically `require` or
otherwise use module dependencies. That's up to you.

The other mandatory file in a module is `config.el`. This file is
executed after all `init.el` files for all modules have been
processed, and after all dependencies have been installed. `config.el`
is supposed to contain code to any module-specific initialization and
configuration. In our example `config.el` looks like this:

  (setq ido-enable-flex-matching t)
  (ido-mode 1)
  (ido-everywhere 1)
  (ido-vertical-mode 1)

This is pretty straightforward and simple, which is typical for
`config.el` files. Rather than put all configuration for all modules
in a single location, `kfg` lets you modularize your configuration
into understandable, independent parts.

In this configuration note that `config.el` calls `(ido-vertical-mode
1)` which relies on the `ido-vertical-mode` package requested in
`init.el`. Since `kfg` promises to install all dependent packages
prior to executing any `config.el` files, the configuration can be
sure that it will be able to call this function.

That's really all there is to `kfg`. You can add as many modules as
you want, and the configurations can be as complex as you need. You
can also easily add someone else's configuration to yours simply by
copying their module directory. You can in principle also have
multiple root directories, each processed by separate calls to
`kfg-initialize`.
