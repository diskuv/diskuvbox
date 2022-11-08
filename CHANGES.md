## 0.1.1

- Use memory buffering to copy files. Removes 16 MiB max file limitation on
  32-bit OCaml.
- Validate and document a bytecode guarantee that only standard stublibs are used
- Distribute binaries with setup-dkml.yml@v1
- Fix Dune build steps so works under cross-compiler
- Code working with Cmdliner.1.1.1
- Increase minimum OCaml to 4.10 to work on macOS
- Cross-compile `darwin_arm64` on `darwin_x86_64`

## 0.1.0

- Initial release
- Error when copy_file SRCFILE is not an existing file
- Error when copy_dir SRCDIR is not an existing directory
- Error when walk_down FROMPATH is not an existing path
- Fix find-up validation removing search names
- Avoid PATH shadowing tests
