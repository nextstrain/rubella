We gratefully acknowledge the authors, originating and submitting
laboratories of the genetic sequences and metadata for sharing their
work. Please note that although data generators have generously shared
data in an open fashion, that does not mean there should be free
license to publish on this data. Data generators should be cited where
possible and collaborations should be sought in some circumstances.
Please try to avoid scooping someone else's work. Reach out if
uncertain.

We maintain two views of rubella evolution.

The first is [`rubella/genome`][], which uses full genome sequences.

The second is [`rubella/E1`][], which uses the 1443bp E1 gene that is
the basis of the [WHO genotypes for rubella][]. Sequences of this
gene, or the 743 base region of it that comprises the office WHO
reference, are much more frequent in NCBI GenBank than whole genome
sequences.

#### Analysis

Our bioinformatic processing workflow can be found at
[github.com/nextstrain/rubella][] and includes:

- sequence alignment by [augur align][]
- phylogenetic reconstruction using [IQTREE-2][]
- ancestral state reconstruction and temporal inference using [TreeTime][]
- genotype assignment using both a [Nextclade dataset][] based on the
  [WHO genotypes for rubella][] as well as genotype metadata extracted
  from NCBI GenBank records

#### Underlying data

We curate sequence data and metadata from NCBI as starting point for
our analyses.

---

Screenshots may be used under a [CC-BY-4.0 license][] and attribution
to nextstrain.org must be provided.

[`rubella/genome`]: https://nextstrain.org/rubella/genome
[`rubella/E1`]: https://nextstrain.org/rubella/E1
[WHO genotypes for rubella]: https://www.who.int/publications/i/item/WER8832
[github.com/nextstrain/rubella]: https://github.com/nextstrain/rubella
[augur align]: https://docs.nextstrain.org/projects/augur/en/stable/usage/cli/align.html
[IQTREE-2]: http://www.iqtree.org/
[TreeTime]: https://github.com/neherlab/treetime
[Nextclade dataset]: FIXME
[CC-BY-4.0 license]: https://creativecommons.org/licenses/by/4.0/
