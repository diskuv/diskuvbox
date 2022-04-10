Use your program. We'll pretend for this example that your program
creates a complex directory structure.
  $ install -d a/b/c/d/e/f
  $ install -d a/b2/c2/d2/e2/f2
  $ install -d a/b2/c3/d3/e3/f3
  $ install -d a/b2/c3/d4/e4/f4
  $ install -d a/b2/c3/d4/e5/f5
  $ install -d a/b2/c3/d4/e5/f6
  $ touch a/b/x
  $ touch a/b/c/y
  $ touch a/b/c/d/z

Use diskuvbox to print the directory tree. It should be reproducible
on any platform that Diskuv Box supports!
  $ ./diskuvbox.exe tree a --max-depth 10 --encoding UTF-8
  a
  ├── b/
  │   ├── c/
  │   │   ├── d/
  │   │   │   ├── e/
  │   │   │   │   └── f/
  │   │   │   └── z
  │   │   └── y
  │   └── x
  └── b2/
      ├── c2/
      │   └── d2/
      │       └── e2/
      │           └── f2/
      └── c3/
          ├── d3/
          │   └── e3/
          │       └── f3/
          └── d4/
              ├── e4/
              │   └── f4/
              └── e5/
                  ├── f5/
                  └── f6/
