# CHANGELOG

We use this CHANGELOG to document breaking changes, new features, bug fixes, and config value changes that may affect both the usage of the workflows and the outputs of the workflows.

## 2026

* 6 August 2026: Added optional configurations param `refine.divergence_units` to support setting divergence units for `augur refine`.

* 4 August 2026: The `filter` section in phylogenetic workflow configuration has been replaced by `subsample`/`custom_subsample`. **This is a breaking change**.
    * NOTE: The 'genome' build does not yet support proximal samples.
