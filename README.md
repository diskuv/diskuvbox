# Diskuv Box

A basic, cross-platform set of commands to manipulate and query the file
system. Available with a [liberal open-source license](LICENSE) as a single
binary (`diskuvbox`, or `diskuvbox.exe` on
Windows) or as an OCaml library with minimal dependencies.

The single binary design is similar to
[busybox](https://www.busybox.net/downloads/BusyBox.html). You can choose to
run a command like `diskuvbox copy-file` *or (PENDING) make a symlink from
`diskuvbox` to `copy-file`*; either way the "copy-file" tooling will be invoked.

All commands meet the following standards:
* Any printed output will be the same on all operating systems *with the default
options*. For example the file search command [find-up](#diskuvbox-find-up) will
print files it finds in `a/b/c` format, even on Windows. You will only get
operating system specific behavior (ex. printing `a\b\c` on Windows) if you
use options like `--native`. **Feel comfortable using the diskuvbox commands
in CRAM tests and expect scripts**.
* On Windows, any failing command will provide a helpful error message if the
paths are over the Windows default 260 character pathname limit.

**Quick Links**

| Section      | Page                                                                   |
| ------------ | ---------------------------------------------------------------------- |
| Usage        | [Add as an Opam Dependency](#add-as-an-opam-dependency)                |
| Usage        | [Using in Dune cram tests](#using-in-dune-cram-tests)                  |
| Usage        | [Using in Opam build steps](#using-in-opam-build-steps)                |
| Usage        | [Using in Dune rules](#using-in-dune-rules)                            |
| Box Commands | [Box Commands](#box-commands)                                          |
| Box Library  | [Box Library](https://diskuv.github.io/diskuvbox/diskuvbox/index.html) |
| Contributing | [Your Contributions](CONTRIBUTORS.md)                                  |

## Usage

### Add as an Opam Dependency

If you are an OCaml developer who creates or maintains an Opam package, add
the following to your `.opam` file:

```powershell
depends: [
  # ...
  "diskuvbox" {>= "0.1.0"}
]
```

or the following to your `dune-project` if Dune auto-generates your opam files:

```lisp
(package
  ; ...
  (depends
    ; ...
    (diskuvbox (>= 0.1.0))
  )
)
```

### Using in Dune cram tests

FIRST, make sure you understand and have enabled [Dune Cram Tests](https://dune.readthedocs.io/en/latest/tests.html#cram-tests-1).

SECOND, make sure you have [Added diskuvbox as an Opam Dependency](#add-as-an-opam-dependency).

FINALLY, go ahead and use `diskuvbox` in your `.t` cram tests like so:

<!-- $MDX file=src/bin/tests/tree-README-example.t -->
```console
Use your program. We'll pretend for this example that your program
creates a complex directory structure.
  $ install -d a/b/c/d/e/f
  $ install -d a/b2/c2/d2/e2/f2
  $ install -d a/b2/c3/d3/e3/f3
  $ install -d a/b2/c3/d4/e4/f4
  $ install -d a/b2/c3/d4/e5/f5
  $ install -d a/b2/c3/d4/e5/f6
  $ touch a/b/x
  $ touch a/b/c/y
  $ touch a/b/c/d/z

Use diskuvbox to print the directory tree. It should be reproducible
on any platform that Diskuv Box supports!
  $ diskuvbox tree a --max-depth 10 --encoding UTF-8
  a
  ├── b/
  │   ├── c/
  │   │   ├── d/
  │   │   │   ├── e/
  │   │   │   │   └── f/
  │   │   │   └── z
  │   │   └── y
  │   └── x
  └── b2/
      ├── c2/
      │   └── d2/
      │       └── e2/
      │           └── f2/
      └── c3/
          ├── d3/
          │   └── e3/
          │       └── f3/
          └── d4/
              ├── e4/
              │   └── f4/
              └── e5/
                  ├── f5/
                  └── f6/
```

### Using in Opam `build` steps

FIRST, make sure you have [Added diskuvbox as an Opam Dependency](#add-as-an-opam-dependency).

SECOND, if you are sure that you *only* need diskuvbox for Opam build steps,
change your `.opam` file so it has a `{build}` filter. For example:

```powershell
depends: [
  # ...
  "diskuvbox" {>= "0.1.0" & build}
]
```

or in your `dune-project` if you auto-generate your .opam files:

```lisp
(package
  ; ...
  (depends
    ; ...
    (diskuvbox (and (>= 0.1.0) :build))
  )
)
```

FINALLY, go ahead and use `diskuvbox` in your .opam build steps like:

```powershell
build: [
  # ...
  ["diskuvbox" "copy-file-into" "assets/icon.png" "assets/public.gpg" "%{_:share}%"]
]
```

### Using in Dune rules

FIRST, make sure you have [Added diskuvbox as an Opam Dependency](#add-as-an-opam-dependency).

THEN, go ahead and use `diskuvbox` as `(run diskuvbox ...)` in the rules of
your `dune` files.

For example, in the source code for this project we have detailed `dune` rules
that ensure each OCaml source file always has our open-source Apache v2.0
license at the top. We use `(run diskuvbox ...)` so that our already complex
rules don't become even more complicated with platform specific hacks:

<!-- $MDX file=src/lib/dune.runlicense.inc -->
```lisp
; This first rule creates "corrected" source code in the Dune build directory
; that always has an Apache v2.0 license at the top of each file.
(rule
 (targets diskuvbox.corrected.ml diskuvbox.corrected.mli)
 (deps
  (:license %{project_root}/etc/license-header.txt)
  (:conf    %{project_root}/etc/headache.conf))
 (action
  (progn
   ; `headache` adds/replaces headers in source code. It is documented at
   ; https://github.com/Frama-C/headache/#readme
   ;
   ; 1. The `headache` program modifies files in-place, so we make a copy of
   ;    the original file.
   ; 2. On Windows `heachache` can fail with "Permission denied" if we don't
   ;    set write permissions on the file.
   ; `diskuvbox` can accomplish both goals on all its supported platforms.
   (run diskuvbox copy-file -m 644 diskuvbox.ml  diskuvbox.corrected.ml)
   (run diskuvbox copy-file -m 644 diskuvbox.mli diskuvbox.corrected.mli)
   ; Add Apache v2.0 license to each file
   (run headache -h %{license} -c %{conf} %{targets})
   ;
   ; `ocamlformat` is used so that our source code modification is idempotent.
   ; (Advanced: Options chosen so that continuous integration tests work with
   ; any version of `ocamlformat`.)
   (run ocamlformat --inplace --disable-conf-files --enable-outside-detected-project %{targets}))))

; These second set of rules let us type:
;      dune build @runlicense --auto-promote
;
; Anytime we type that Dune will take the corrected source code from the Dune
; build directory and use it to modify the original source code.
(rule
 (alias runlicense)
 (action
   (diff diskuvbox.ml  diskuvbox.corrected.ml)))
(rule
 (alias runlicense)
 (action
   (diff diskuvbox.mli diskuvbox.corrected.mli)))
```

## Box commands

> Looking for the **[OCaml library](https://diskuv.github.io/diskuvbox/diskuvbox/index.html)**?
> The library documentation is
> available at https://diskuv.github.io/diskuvbox/diskuvbox/index.html.
> Just use `opam install diskuvbox` (or `with-dkml opam install diskuvbox` with
> the Diskuv OCaml Windows distribution) to install Diskuv Box in your existing
> OCaml project.


| Command                                     | Description                                                               |
| ------------------------------------------- | ------------------------------------------------------------------------- |
| [copy-dir](#diskuvbox-copy-dir)             | Copy content of one or more source directories to a destination directory |
| [copy-file](#diskuvbox-copy-file)           | Copy a source file to a destination file                                  |
| [copy-file-into](#diskuvbox-copy-file-into) | Copy one or more files into a destination directory                       |
| [find-up](#diskuvbox-find-up)               | Find a file in the current directory or one of its ancestors              |
| [touch](#diskuvbox-touch)                   | Touch one or more files                                                   |
| [tree](#diskuvbox-tree)                     | Print a directory tree                                                    |

If you would like to add or modify a Box command, head over to
**[Your Contributions](CONTRIBUTORS.md)**.

### diskuvbox copy-dir

```console
$ diskuvbox copy-dir --help
NAME
       diskuvbox-copy-dir - Copy content of one or more source directories to
       a destination directory.

SYNOPSIS
       diskuvbox copy-dir [OPTION]... SRCDIR... DESTDIR

DESCRIPTION
       Copy content of one or more SRCDIR... directories to the DESTDIR
       directory. copy-dir will follow symlinks.

ARGUMENTS
       DESTDIR (required)
           Destination directory. If DESTDIR does not exist it will be
           created.

       SRCDIR (required)
           One or more source directories to copy. The command fails when a
           SRCDIR does not exist.

OPTIONS
       --color=WHEN (absent=auto)
           Colorize the output. WHEN must be one of `auto', `always' or
           `never'.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of `auto',
           `pager', `groff' or `plain'. With `auto', the format is `pager` or
           `plain' whenever the TERM env var is `dumb' or undefined.

       -q, --quiet
           Be quiet. Takes over -v and --verbosity.

       -v, --verbose
           Increase verbosity. Repeatable, but more than twice does not bring
           more.

       --verbosity=LEVEL (absent=warning)
           Be more or less verbose. LEVEL must be one of `quiet', `error',
           `warning', `info' or `debug'. Takes over -v.

       --version
           Show version information.

EXIT STATUS
       copy-dir exits with the following status:

       0   on success.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

```

### diskuvbox copy-file

```console
$ diskuvbox copy-file --help
NAME
       diskuvbox-copy-file - Copy a source file to a destination file.

SYNOPSIS
       diskuvbox copy-file [OPTION]... SRCFILE DESTFILE

DESCRIPTION
       Copy the SRCFILE to the DESTFILE. copy-file will follow symlinks.

ARGUMENTS
       DESTFILE (required)
           Destination file. If DESTFILE does not exist it will be created.

       SRCFILE (required)
           The source file to copy. The command fails when a SRCFILE does not
           exist.

OPTIONS
       --color=WHEN (absent=auto)
           Colorize the output. WHEN must be one of `auto', `always' or
           `never'.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of `auto',
           `pager', `groff' or `plain'. With `auto', the format is `pager` or
           `plain' whenever the TERM env var is `dumb' or undefined.

       -m VAL, --mode=VAL
           The chmod mode permission of the destination file, in octal. If
           not specified then the chmod mode permission of the source file is
           used. Examples: 644, 755.

       -q, --quiet
           Be quiet. Takes over -v and --verbosity.

       -v, --verbose
           Increase verbosity. Repeatable, but more than twice does not bring
           more.

       --verbosity=LEVEL (absent=warning)
           Be more or less verbose. LEVEL must be one of `quiet', `error',
           `warning', `info' or `debug'. Takes over -v.

       --version
           Show version information.

EXIT STATUS
       copy-file exits with the following status:

       0   on success.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

```

### diskuvbox copy-file-into

```console
$ diskuvbox copy-file-into --help
NAME
       diskuvbox-copy-file-into - Copy one or more files into a destination
       directory.

SYNOPSIS
       diskuvbox copy-file-into [OPTION]... SRCFILE... DESTDIR

DESCRIPTION
       Copy one or more SRCFILE... files to the DESTDIR directory.
       copy-files-into will follow symlinks.

ARGUMENTS
       DESTDIR (required)
           Destination directory. If DESTDIR does not exist it will be
           created.

       SRCFILE (required)
           One or more source files to copy. The command fails when a SRCFILE
           does not exist.

OPTIONS
       --color=WHEN (absent=auto)
           Colorize the output. WHEN must be one of `auto', `always' or
           `never'.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of `auto',
           `pager', `groff' or `plain'. With `auto', the format is `pager` or
           `plain' whenever the TERM env var is `dumb' or undefined.

       -m VAL, --mode=VAL
           The chmod mode permission of the destination file, in octal. If
           not specified then the chmod mode permission of the source file is
           used. Examples: 644, 755.

       -q, --quiet
           Be quiet. Takes over -v and --verbosity.

       -v, --verbose
           Increase verbosity. Repeatable, but more than twice does not bring
           more.

       --verbosity=LEVEL (absent=warning)
           Be more or less verbose. LEVEL must be one of `quiet', `error',
           `warning', `info' or `debug'. Takes over -v.

       --version
           Show version information.

EXIT STATUS
       copy-file-into exits with the following status:

       0   on success.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

```

### diskuvbox find-up

```console
$ diskuvbox find-up --help
NAME
       diskuvbox-find-up - Find a file in the current directory or one of its
       ancestors.

SYNOPSIS
       diskuvbox find-up [OPTION]... FROMDIR BASENAME...

DESCRIPTION
       Find a file that matches the name as one or more specified FILE...
       files in the FROMDIR directory.

       Will print the matching file if found. Otherwise will print nothing.

ARGUMENTS
       BASENAME (required)
           One or more basenames to search. The command fails when a BASENAME
           is blank or has a directory separator.

       FROMDIR (required)
           Directory to search. The command fails when FROMDIR does not
           exist.

OPTIONS
       --color=WHEN (absent=auto)
           Colorize the output. WHEN must be one of `auto', `always' or
           `never'.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of `auto',
           `pager', `groff' or `plain'. With `auto', the format is `pager` or
           `plain' whenever the TERM env var is `dumb' or undefined.

       --native
           Print files and directories in native format. On Windows the
           native format uses backslashes as directory separators, while on
           Unix (including macOS) the native format uses forward slashes. If
           --native is not specified then all files and directories are
           printed with the directory separators as forward slashes.

       -q, --quiet
           Be quiet. Takes over -v and --verbosity.

       -v, --verbose
           Increase verbosity. Repeatable, but more than twice does not bring
           more.

       --verbosity=LEVEL (absent=warning)
           Be more or less verbose. LEVEL must be one of `quiet', `error',
           `warning', `info' or `debug'. Takes over -v.

       --version
           Show version information.

EXIT STATUS
       find-up exits with the following status:

       0   on success.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

```

### diskuvbox touch

```console
$ diskuvbox touch --help
NAME
       diskuvbox-touch-file - Touch one or more files.

SYNOPSIS
       diskuvbox touch-file [OPTION]... FILE...

DESCRIPTION
       Touch one or more FILE... files.

ARGUMENTS
       FILE (required)
           One or more files to touch. If a FILE does not exist it will be
           created.

OPTIONS
       --color=WHEN (absent=auto)
           Colorize the output. WHEN must be one of `auto', `always' or
           `never'.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of `auto',
           `pager', `groff' or `plain'. With `auto', the format is `pager` or
           `plain' whenever the TERM env var is `dumb' or undefined.

       -q, --quiet
           Be quiet. Takes over -v and --verbosity.

       -v, --verbose
           Increase verbosity. Repeatable, but more than twice does not bring
           more.

       --verbosity=LEVEL (absent=warning)
           Be more or less verbose. LEVEL must be one of `quiet', `error',
           `warning', `info' or `debug'. Takes over -v.

       --version
           Show version information.

EXIT STATUS
       touch-file exits with the following status:

       0   on success.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

```

### diskuvbox tree

```console
$ diskuvbox tree --help
NAME
       diskuvbox-tree - Print a directory tree.

SYNOPSIS
       diskuvbox tree [OPTION]... DIR

DESCRIPTION
       Print the directory tree starting at the DIR directory.

ARGUMENTS
       DIR (required)
           Directory to print. The command fails when DIR does not exist.

OPTIONS
       --color=WHEN (absent=auto)
           Colorize the output. WHEN must be one of `auto', `always' or
           `never'.

       -d VAL, --max-depth=VAL (absent=0)
           Maximum depth to print. A maximum depth of 0 will never print
           deeper than the name of the starting directory. A maximum depth of
           1 will, at most, print the contents of the starting directory.
           Defaults to 0

       -e VAL, --encoding=VAL (absent=ASCII)
           The encoding of the graphic characters printed: ASCII, UTF-8.
           Defaults to ASCII

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of `auto',
           `pager', `groff' or `plain'. With `auto', the format is `pager` or
           `plain' whenever the TERM env var is `dumb' or undefined.

       --native
           Print files and directories in native format. On Windows the
           native format uses backslashes as directory separators, while on
           Unix (including macOS) the native format uses forward slashes. If
           --native is not specified then all files and directories are
           printed with the directory separators as forward slashes.

       -q, --quiet
           Be quiet. Takes over -v and --verbosity.

       -v, --verbose
           Increase verbosity. Repeatable, but more than twice does not bring
           more.

       --verbosity=LEVEL (absent=warning)
           Be more or less verbose. LEVEL must be one of `quiet', `error',
           `warning', `info' or `debug'. Takes over -v.

       --version
           Show version information.

EXIT STATUS
       tree exits with the following status:

       0   on success.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

```

## Contributions

Head over to **[Your Contributions](CONTRIBUTORS.md)**.

## Acknowledgements

The first implementations of Diskuv Box were implemented with the assistance of
the [OCaml Software Foundation (OCSF)](http://ocaml-sf.org),
a sub-foundation of the [INRIA Foundation](https://www.inria.fr).

Two OCaml libraries ([bos](https://erratique.ch/software/bos) and
[cmdliner](https://erratique.ch/software/cmdliner)) are essential to Diskuv Box;
these libraries were created by [Daniel Bünzli](https://erratique.ch/profile).

## Status

| Status                                                                                                                                                          |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Box tests](https://github.com/diskuv/diskuvbox/actions/workflows/test.yml/badge.svg)](https://github.com/diskuv/diskuvbox/actions/workflows/test.yml)        |
| [![Syntax check](https://github.com/diskuv/diskuvbox/actions/workflows/syntax.yml/badge.svg)](https://github.com/diskuv/diskuvbox/actions/workflows/syntax.yml) |
