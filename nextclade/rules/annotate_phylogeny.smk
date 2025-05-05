"""
This part of the workflow creates additonal annotations for the phylogenetic tree.
"""


rule ancestral:
    input:
        alignment="results/aligned.fasta",
        tree="results/tree.nwk",
    output:
        node_data="results/nt_muts.json",
    params:
        inference=config["ancestral"]["inference"],
        reference_fasta=config["files"]["reference_E1_fasta"],
    log:
        "logs/ancestral.txt",
    benchmark:
        "benchmarks/ancestral.txt"
    shell:
        r"""
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference}  \
            --root-sequence {params.reference_fasta} \
         2>&1 | tee {log:q}
        """


rule translate:
    input:
        tree="results/tree.nwk",
        node_data="results/nt_muts.json",
        reference=config["files"]["reference_E1_gff"],
    output:
        node_data="results/aa_muts.json",
    log:
        "logs/translate.txt",
    benchmark:
        "benchmarks/translate.txt"
    shell:
        r"""
        augur translate \
            --tree {input.tree:q} \
            --ancestral-sequences {input.node_data:q} \
            --reference-sequence {input.reference:q} \
            --output {output.node_data:q} \
          2>&1 | tee {log:q}
        """


rule clades:
    input:
        tree="results/tree.nwk",
        nt_muts="results/nt_muts.json",
        aa_muts="results/aa_muts.json",
        clade_defs=config["files"]["clades"],
    output:
        clades="results/clades.json",
    log:
        "logs/clades.txt",
    benchmark:
        "benchmarks/clades.txt"
    shell:
        r"""
        augur clades \
            --tree {input.tree:q} \
            --mutations {input.nt_muts} {input.aa_muts} \
            --clades {input.clade_defs:q} \
            --output {output.clades:q} \
          2>&1 | tee {log:q}
        """
