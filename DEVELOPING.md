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

```bash
opam install dune-release
dune-release distrib -p diskuvbox
dune-release publish distrib -p diskuvbox
dune-release opam pkg -p diskuvbox
dune-release opam submit -p diskuvbox
```
