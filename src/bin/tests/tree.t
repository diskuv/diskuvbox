Create a complex directory structure
  $ install -d a/b/c/d/e/f
  $ install -d a/b2/c2/d2/e2/f2
  $ install -d a/b2/c3/d3/e3/f3
  $ install -d a/b2/c3/d4/e4/f4
  $ install -d a/b2/c3/d4/e5/f5
  $ install -d a/b2/c3/d4/e5/f6
  $ touch a/b/x
  $ touch a/b/c/y
  $ touch a/b/c/d/z

Use diskuvbox to print the directory tree with depth <= 0
  $ ./diskuvbox.exe tree a --max-depth 0
  a

Use diskuvbox to print the directory tree with depth <= 2
  $ ./diskuvbox.exe tree a --max-depth 2
  a
  |-- b/
  |   |-- c/
  |   `-- x
  `-- b2/
      |-- c2/
      `-- c3/

Use diskuvbox to print the directory tree, all of it
  $ ./diskuvbox.exe tree a --max-depth 10
  a
  |-- b/
  |   |-- c/
  |   |   |-- d/
  |   |   |   |-- e/
  |   |   |   |   `-- f/
  |   |   |   `-- z
  |   |   `-- y
  |   `-- x
  `-- b2/
      |-- c2/
      |   `-- d2/
      |       `-- e2/
      |           `-- f2/
      `-- c3/
          |-- d3/
          |   `-- e3/
          |       `-- f3/
          `-- d4/
              |-- e4/
              |   `-- f4/
              `-- e5/
                  |-- f5/
                  `-- f6/

Use diskuvbox to print the directory tree, all of it in UTF-8
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

Use diskuvbox to print a subtree of the directory tree
  $ ./diskuvbox.exe tree a/b --max-depth 10
  a/b
  |-- c/
  |   |-- d/
  |   |   |-- e/
  |   |   |   `-- f/
  |   |   `-- z
  |   `-- y
  `-- x
