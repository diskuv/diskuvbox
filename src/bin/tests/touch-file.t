Create non-empty files.
| Since modification timestamps are hard to test cross-platform (portably), we
| only do it if BOX_TIMESTAMP_TESTS=true
  $ echo hello > t_created_first
  $ if [ "$BOX_TIMESTAMP_TESTS" = true ]; then sleep 0.1; fi
  $ echo hello > t_created_later
  $ if [ "$BOX_TIMESTAMP_TESTS" != true ] || [ t_created_later -nt t_created_first ]; then echo GOOD; else echo BAD; fi
  GOOD

Use diskuvbox to create files
  $ ./diskuvbox.exe touch-file a b c d/e f/g/h t_created_first

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
  $ if [ "$BOX_TIMESTAMP_TESTS" != true ] || [ t_created_first -nt t_created_later ]; then echo GOOD; else echo BAD; fi
  GOOD
