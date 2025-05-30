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
        augur ancestral \
            --tree {input.tree:q} \
            --alignment {input.alignment:q} \
            --output-node-data {output.node_data:q} \
            --inference {params.inference:q} \
          2>&1 | tee {log:q}
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
        augur translate \
            --tree {input.tree:q} \
            --ancestral-sequences {input.node_data:q} \
            --reference-sequence {input.genemap:q} \
            --output {output.node_data:q} \
          2>&1 | tee {log:q}
        """


rule clades:
    """Annotating clades"""
    input:
        tree="results/{build}/tree.nwk",
        nt_muts="results/{build}/nt_muts.json",
        aa_muts="results/{build}/aa_muts.json",
        clade_defs=lambda w: config["files"][w.build]["clades"],
    output:
        clades="results/{build}/clades.json",
    log:
        "logs/{build}/clades.txt",
    benchmark:
        "benchmarks/{build}/clades.txt"
    shell:
        r"""
        augur clades \
          --tree {input.tree:q} \
          --mutations {input.nt_muts:q} {input.aa_muts:q} \
          --clades {input.clade_defs:q} \
          --output {output.clades:q} \
        2>&1 | tee {log:q}
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
        augur traits \
            --tree {input.tree:q} \
            --metadata {input.metadata:q} \
            --output {output.node_data:q} \
            --metadata-id-columns {params.strain_id:q} \
            --columns {params.columns} \
            --confidence \
          2>&1 | tee {log:q}
        """
