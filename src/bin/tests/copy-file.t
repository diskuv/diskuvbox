Show that nothing is in the directory
  $ ls | sort
  copy-file.t

Create a file
  $ touch a

Create a symlink
  $ touch m
  $ ln -s m n

Use diskuvbox to copy each one at a time. The destination directory should be autocreated.
  $ ../main.exe copy-file a dest/1/2/a_copied
  $ ../main.exe copy-file n dest/1/2/n_copied

Verify
  $ ls dest/1/2 | sort
  a_copied
  n_copied
