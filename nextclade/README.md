# Rubella Virus Nextclade Dataset Tree

This workflow creates a phylogenetic tree that can be used as part of
a Nextclade dataset to assign genotypes to rubella virus samples based
on ["Rubella virus nomenclature update: 2013"][].

* Build a tree using samples from the `ingest` output, with the following
  sampling criteria:
  * Force-include the following samples:
    * genotype reference strains from Table 1 of ["Rubella virus
      nomenclature update: 2013"][]
    * three additional vaccine-derived strains of genotype 1a that
      were empirically identified during construction of this dataset
* Assign genotypes to each sample and internal nodes of the tree with
  `augur clades`, using clade-defining mutations in `defaults/clades.tsv`
* Provide the following coloring options on the tree:
  * Genotype assignment from `augur clades`

## How to create a new tree

* Run the workflow: `nextstrain build .`
* Inspect the output tree by comparing genotype assignments from the following sources:
  * `augur clades` output
* If unwanted samples are present in the tree, add them to
  `defaults/dropped_strains.tsv` and re-run the workflow
* If any changes are needed to the clade-defining mutations, add
  changes to `defaults/clades.tsv` and re-run the workflow
* Repeat as needed

["Rubella virus nomenclature update: 2013"]: https://www.who.int/publications/i/item/WER8832
