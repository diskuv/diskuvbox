Use diskuvbox to find a nonexistent file
  $ diskuvbox find-up . 09535a27-1559-492e-b674-b1a680623190.does.not.exist

Create a directory structure
  $ install -d a/b/c/d/e/f
  $ touch a/b/i-am-here
  $ touch a/b/c/i-am-also-here
  $ touch a/b/c/d/something-that-wont-be-searched

Use diskuvbox to find i-am-here
  $ diskuvbox find-up a/b/c/d/e/f i-am-here
  a/b/i-am-here

Use diskuvbox to find i-am-here or i-am-also-here
  $ diskuvbox find-up a/b/c/d/e/f i-am-here i-am-also-here
  a/b/c/i-am-also-here
