"""
This part of the workflow creates additional annotations for the
phylogenetic tree.
"""


rule ancestral:
    """Reconstructing ancestral sequences and mutations"""
    input:
        tree="results/{build}/tree.nwk",
        alignment="results/{build}/aligned_and_filtered.fasta",
    output:
        node_data="results/{build}/nt_muts.json",
    params:
        inference=config["ancestral"]["inference"],
    log:
        "logs/{build}/ancestral.txt",
    benchmark:
        "benchmarks/{build}/ancestral.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur ancestral \
            --tree {input.tree:q} \
            --alignment {input.alignment:q} \
            --output-node-data {output.node_data:q} \
            --inference {params.inference:q}
        """


rule translate:
    """Translating amino acid sequences"""
    input:
        tree="results/{build}/tree.nwk",
        node_data="results/{build}/nt_muts.json",
        genemap="defaults/genemap_{build}.gff",
    output:
        node_data="results/{build}/aa_muts.json",
    log:
        "logs/{build}/translate.txt",
    benchmark:
        "benchmarks/{build}/translate.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur translate \
            --tree {input.tree:q} \
            --ancestral-sequences {input.node_data:q} \
            --reference-sequence {input.genemap:q} \
            --output {output.node_data:q}
        """


rule traits:
    """Inferring ancestral traits for {params.columns!s}"""
    input:
        tree="results/{build}/tree.nwk",
        metadata="data/metadata.tsv",
    output:
        node_data="results/{build}/traits.json",
    params:
        strain_id=config["strain_id_field"],
        columns=config["traits"]["columns"],
    log:
        "logs/{build}/traits.txt",
    benchmark:
        "benchmarks/{build}/traits.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur traits \
            --tree {input.tree:q} \
            --metadata {input.metadata:q} \
            --output {output.node_data:q} \
            --metadata-id-columns {params.strain_id:q} \
            --columns {params.columns} \
            --confidence
        """
