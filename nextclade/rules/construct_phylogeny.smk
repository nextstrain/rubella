"""
This part of the workflow constructs the phylogenetic tree.
"""


rule tree:
    input:
        alignment="results/aligned.fasta",
    output:
        tree="results/tree_raw.nwk",
    log:
        "logs/tree.txt",
    benchmark:
        "benchmarks/tree.txt"
    shell:
        r"""
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree} \
          2>&1 | tee {log:q}
        """


rule refine:
    input:
        alignment="results/aligned.fasta",
        metadata="data/metadata.tsv",
        tree="results/tree_raw.nwk",
    output:
        node_data="results/branch_lengths.json",
        tree="results/tree.nwk",
    params:
        strain_id=config["strain_id_field"],
    log:
        "logs/refine.txt",
    benchmark:
        "benchmarks/refine.txt"
    shell:
        r"""
        augur refine \
            --tree {input.tree:q} \
            --alignment {input.alignment:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --output-tree {output.tree:q} \
            --output-node-data {output.node_data:q} \
            --root mid_point \
          2>&1 | tee {log:q}
        """
