Use diskuvbox to find a nonexistent file
  $ ./diskuvbox.exe find-up . 09535a27-1559-492e-b674-b1a680623190.does.not.exist

Create a directory structure
  $ install -d a/b/c/d/e/f
  $ ./diskuvbox.exe touch a/b/i-am-here
  $ ./diskuvbox.exe touch a/b/c/i-am-also-here
  $ ./diskuvbox.exe touch a/b/c/d/something-that-wont-be-searched

Use diskuvbox to find i-am-here
  $ ./diskuvbox.exe find-up a/b/c/d/e/f i-am-here
  a/b/i-am-here

Use diskuvbox to find i-am-here or i-am-also-here
  $ ./diskuvbox.exe find-up a/b/c/d/e/f i-am-here i-am-also-here
  a/b/c/i-am-also-here

Use diskuvbox to find .you-better-find-me in the same directory
  $ ./diskuvbox.exe touch .you-better-find-me
  $ ./diskuvbox.exe find-up . .you-better-find-me
  ./.you-better-find-me

Use diskuvbox to find .and-this-one-too in a child directory
  $ install -d z
  $ ./diskuvbox.exe touch z/.and-this-one-too
  $ ./diskuvbox.exe find-up z .and-this-one-too
  z/.and-this-one-too
