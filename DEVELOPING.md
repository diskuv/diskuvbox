# Developing

## Upgrading the DKML scripts

```bash
opam install ./diskuvbox.opam --deps-only
opam upgrade dkml-workflows

# Regenerate the DKML workflow scaffolding
opam exec -- generate-setup-dkml-scaffold && dune build '@gen-dkml' --auto-promote && dune build '@ci/setup-dkml/fmt'
```

## Releasing

> Do not use `dune-release bistro -p diskuvbox` since it does not work with our GitHub Actions
> generated documentation

1. Update the version in `dune-project`.
2. Run:

   ```shell
   dune build
   git commit -m "Bump version" *.opam
   VERSION=$(awk '$1=="(version" {print $2}' dune-project | tr -d ')')
   git tag -a -m "Version $VERSION" $VERSION
   git push
4. Make sure GitHub Actions succeeds
5. Run:

   ```shell
   VERSION=$(awk '$1=="(version" {print $2}' dune-project | tr -d ')')
   git push origin $VERSION
   opam install dune-release
   dune-release distrib -p diskuvbox
   dune-release publish distrib -p diskuvbox
   dune-release opam pkg -p diskuvbox
   dune-release opam submit -p diskuvbox
   ```
