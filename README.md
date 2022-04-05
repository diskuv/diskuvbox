# diskuvbox

A cross-platform basic set of script commands. Available as a single
binary (`diskuvbox`, or `diskuvbox.exe` on Windows) and as an OCaml
library.

The single binary design is similar to
[busybox](https://www.busybox.net/downloads/BusyBox.html). You can choose to
run a command like `diskuvbox cp` or make a symlink from `diskuvbox` to `cp`;
either way the "cp" tooling will be invoked.

The "basic" set of commands was meant to provide the same amount of functionality
as [cmake -E](https://cmake.org/cmake/help/latest/manual/cmake.1.html#run-a-command-line-tool).

On Windows, any failing command will provide an error message if the paths are
over the default 260 character pathname limit.

## Script commands

### diskuvbox copy-dir

### diskuvbox copy-file
