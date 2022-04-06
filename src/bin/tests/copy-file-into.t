Show that nothing is in the directory
  $ ls | sort
  copy-file-into.t

Create a file
  $ touch a

Create a symlink
  $ touch m
  $ ln -s m n

Use diskuvbox to copy them. The destination directory should be autocreated.
  $ ../main.exe copy-file-into a n dest/1/2/3

Verify
  $ ls dest/1/2/3 | sort
  a
  n
