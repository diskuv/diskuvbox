# Developing

## Upgrading the DKML scripts

```bash
opam install ./diskuvbox.opam --deps-only
opam upgrade dkml-workflows

# Regenerate the DKML workflow scaffolding
opam exec -- generate-setup-dkml-scaffold && dune build '@gen-dkml' --auto-promote
```
