Show that nothing is in the directory
  $ ls | sort
  touch-file.t

Create a non-empty file
  $ echo hello > t_created_first
  $ echo hello > t_created_later
  $ if [ t_created_later -nt t_created_first ]; then echo GOOD; else echo BAD; fi
  GOOD

Use diskuvbox to create files
  $ ../main.exe touch-file a b c d/e f/g/h t_created_first

Verify new files were created
  $ ls | sort
  a
  b
  c
  d
  f
  t_created_first
  t_created_later
  touch-file.t
  $ ls d | sort
  e
  $ ls f | sort
  g
  $ ls f/g | sort
  h

Verify that the pre-existing touched file still has the same contents
  $ cat t_created_first
  hello

Verify that the pre-existing touched file has timestamp newer than a file created later
  $ if [ t_created_first -nt t_created_later ]; then echo GOOD; else echo BAD; fi
  GOOD
