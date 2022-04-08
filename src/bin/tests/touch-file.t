Create a non-empty file
  $ echo hello > t_created_first
  $ sleep 0.1
  $ echo hello > t_created_later
  $ if [ t_created_later -nt t_created_first ]; then echo GOOD; else echo BAD; fi
  GOOD

Use diskuvbox to create files
  $ ../main.exe touch-file a b c d/e f/g/h t_created_first

Verify new files were created
  $ ls a b c t_created_first t_created_later
  a
  b
  c
  t_created_first
  t_created_later
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
