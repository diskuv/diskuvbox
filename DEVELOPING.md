# Developing

## Upgrading the DKML scripts

```bash
opam upgrade dkml-workflows

# Regenerate the DKML workflow scaffolding
opam exec -- generate-setup-dkml-scaffold && dune build '@gen-dkml' --auto-promote
```
