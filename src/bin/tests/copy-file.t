Create a file
  $ touch a

Create a symlink
  $ touch m
  $ ln -s m n

Use diskuvbox to copy each one at a time. The destination directory should be autocreated.
  $ ./diskuvbox.exe copy-file a dest/1/2/a_copied
  $ ./diskuvbox.exe copy-file n dest/1/2/n_copied

Verify
  $ ls dest/1/2 | sort
  a_copied
  n_copied
