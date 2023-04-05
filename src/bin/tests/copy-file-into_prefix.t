Create files
  $ touch a m

Use diskuvbox to copy them. The destination directory should be autocreated.
  $ ./diskuvbox.exe copy-file-into --prefix rewrite- a m dest/1/2/3

Verify
  $ ls dest/1/2/3 | sort
  rewrite-a
  rewrite-m
