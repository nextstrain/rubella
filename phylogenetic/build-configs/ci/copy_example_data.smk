rule copy_example_data:
    input:
        sequences="example-data/sequences.fasta.zst",
        metadata="example-data/metadata.tsv.zst",
    output:
        sequences=temp("data/sequences.fasta.zst"),
        metadata=temp("data/metadata.tsv.zst"),
    shell:
        """
        cp -f {input.sequences} {output.sequences}
        cp -f {input.metadata} {output.metadata}
        """


# force this rule over downloading from nextstrain
ruleorder: copy_example_data > download
