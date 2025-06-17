"""
This part of the workflow assembles a nextclade dataset.
"""


rule assemble_dataset:
    input:
        reference_fasta="defaults/reference.fasta",
        tree=config["files"]["auspice_json"],
        sequences="defaults/sequences.fasta",
        annotation="defaults/genome_annotation.gff3",
        pathogen_json="defaults/nextclade-dataset/pathogen.json",
        readme="defaults/nextclade-dataset/README.md",
        changelog="defaults/nextclade-dataset/CHANGELOG.md",
    output:
        reference_fasta="dataset/reference.fasta",
        tree="dataset/tree.json",
        pathogen_json="dataset/pathogen.json",
        sequences="dataset/sequences.fasta",
        annotation="dataset/genome_annotation.gff3",
        readme="dataset/README.md",
        changelog="dataset/CHANGELOG.md",
    log:
        "logs/assemble_dataset.txt",
    benchmark:
        "benchmarks/assemble_dataset.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        cp -v {input.reference_fasta:q} {output.reference_fasta:q}
        cp -v {input.tree:q} {output.tree:q}
        cp -v {input.pathogen_json:q} {output.pathogen_json:q}
        cp -v {input.annotation:q} {output.annotation:q}
        cp -v {input.readme:q} {output.readme:q}
        cp -v {input.changelog:q} {output.changelog:q}
        cp -v {input.sequences:q} {output.sequences:q}
        """


rule test_dataset:
    input:
        sequences="data/sequences.fasta",
        # this isn't used by the command below, but it is included as
        # an input to force the preceding rule to finish running
        # before this one starts
        tree="dataset/tree.json",
    output:
        outdir=directory("test_output/"),
    params:
        dataset_dir="dataset",
    log:
        "logs/test_dataset.txt",
    benchmark:
        "benchmarks/test_dataset.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        nextclade run \
            --input-dataset {params.dataset_dir:q} \
            --output-all {output.outdir:q} \
            --silent \
          {input.sequences:q}
        """
