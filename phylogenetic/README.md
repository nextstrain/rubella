# Phylogenetic workflow for rubella virus

This workflow uses metadata and sequences to produce two
[Nextstrain datasets][] that can be visualized in Auspice, one for the
whole rubella genome, and one specific for the E1 gene.

## Data Requirements

The core phylogenetic workflow will use metadata values as-is, so
please do any desired data formatting and curations as part of the
[ingest][] workflow.

1. The metadata must include an ID column that can be used as as exact
   match for the sequence ID present in the FASTA headers.
2. The `date` column in the metadata must be in ISO 8601 date format
   (i.e. YYYY-MM-DD).
3. Ambiguous dates should be masked with `XX` (e.g. 2023-01-XX).

## Config

[defaults/config.yaml][] contains all of the default configuration
parameters used for the phylogenetic workflow. Use Snakemake's
`--configfile`/`--config` options to override these default values.

## Snakefile and rules

The rules directory contains separate Snakefiles (`*.smk`) as modules
of the core phylogenetic workflow. The modules of the workflow are in
separate files to keep the main ingest [Snakefile][] succinct and
organized. Modules are all [included][] in the main Snakefile in the
order that they are expected to run.

[defaults/config.yaml]: ./config/defaults.yaml
[included]: https://snakemake.readthedocs.io/en/stable/snakefiles/modularization.html#includes
[ingest]: ../ingest/
[Nextstrain datasets]: https://docs.nextstrain.org/en/latest/reference/glossary.html#term-dataset
[Snakefile]: ./Snakefile
