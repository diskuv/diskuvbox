# Your Contributions

Diskuv Box accepts Pull Requests (PRs)!

Before you start writing a PR, please be aware of three things:
1. The project code is under the Apache v2.0 license. People *will* be able
   to use your contributions for commercial code!
2. We only accept PRs that have signed the [Developer Certificate of Origin (DCO)](https://developercertificate.org/)
   license. You sign by including a `Signed-off-by` line
   with an email address that matches the commit author. For example, your
   commit message could look like:

   ```
   This is my commit message

   Signed-off-by: Random J Developer <random@developer.example.org>   
   ```
   
   or you can just use `git commit -s -m 'This is my commit message'`.
3. Especially if this is your first PR, it is helpful to open an issue first
   so your upcoming contribution idea can be sanity tested.

If you would like to develop a new Box command, you will need to:

* Add a function to the library at [src/lib/diskuvbox.mli](src/lib/diskuvbox.mli)
  and [src/lib/diskuvbox.ml](src/lib/diskuvbox.ml). Each command usually
  gets its own library function, but there are exceptions like
  the [copy-file](README.md#diskuvbox-copy-file) and [copy-file-into](README.md#diskuvbox-copy-file) commands that both use the same
  [copy_file](https://diskuv.github.io/diskuvbox/diskuvbox/Diskuvbox/index.html#val-copy_file) library function.
* Add a CLI command to [src/bin/main.ml](src/bin/main.ml).
* Add a new test file in [src/bin/tests/](src/bin/tests/). Run them
  with `dune runtest`.
* Add your new command to the `README.md` document. The help and examples
  in that document (for ones that start with ` ```console `) should be automatically generated after you run
  `dune build @runmarkdown --auto-promote`.

Before submitting your PR make sure you have:
1. Run `dune build`
2. Run `dune runtest`
3. Run `dune build @runmarkdown --auto-promote`
4. Run `dune build @runlicense --auto-promote`
