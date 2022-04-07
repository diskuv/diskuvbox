# Diskuv Box

A basic, cross-platform set of commands to manipulate and query the file
system. Available as a single binary (`diskuvbox`, or `diskuvbox.exe` on
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

## Box commands

| Command                                     | Description                                                               |
| ------------------------------------------- | ------------------------------------------------------------------------- |
| [copy-dir](#diskuvbox-copy-dir)             | Copy content of one or more source directories to a destination directory |
| [copy-file](#diskuvbox-copy-file)           | Copy a source file to a destination file                                  |
| [copy-file-into](#diskuvbox-copy-file-into) | Copy one or more files into a destination directory                       |
| [find-up](#diskuvbox-find-up)               | Find a file in the current directory or one of its ancestors              |
| [touch](#diskuvbox-touch)                   | Touch one or more files                                                   |

### diskuvbox copy-dir

```console
$ src/bin/main.exe copy-dir --help
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
$ src/bin/main.exe copy-file --help
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
$ src/bin/main.exe copy-file-into --help
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
$ src/bin/main.exe find-up --help
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
$ src/bin/main.exe touch --help
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
