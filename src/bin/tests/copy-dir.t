Create a few files in src1/, including a subdirectory
  $ install -d src1
  $ touch src1/a src1/b src1/c
  $ install -d src1/s
  $ touch src1/s/t

Create a few files in src2/, including one dotfile which is sometimes hidden
  $ install -d src2
  $ touch src2/x src2/y src2/z src2/.dotfile

Create empty directory src3/
  $ install -d src3

Create directory src4/ with a symlink
  $ install -d src4
  $ touch src4/m
  $ ln -s m src4/n

Use diskuvbox to copy them. The destination directory should be autocreated.
  $ ./diskuvbox.exe copy-dir src1 src2 src3 src4 dest

Verify
  $ ls dest | sort
  a
  b
  c
  m
  n
  s
  x
  y
  z
  $ ls dest/s | sort
  t
