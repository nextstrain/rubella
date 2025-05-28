"""
This part of the workflow constructs the phylogenetic tree.
"""


rule tree:
    """Building tree"""
    input:
        alignment="results/{build}/aligned_and_filtered.fasta",
    output:
        tree="results/{build}/tree_raw.nwk",
    threads: workflow.cores * 0.5
    log:
        "logs/{build}/tree.txt",
    benchmark:
        "benchmarks/{build}/tree.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur tree \
            --alignment {input.alignment:q} \
            --output {output.tree:q} \
            --nthreads {threads}
        """


rule refine:
    """
    Refining tree
      - use {params.coalescent} coalescent timescale
      - estimate {params.date_inference} node dates
      - filter tips more than {params.clock_filter_iqd} IQDs from clock expectation
    """
    input:
        tree="results/{build}/tree_raw.nwk",
        alignment="results/{build}/aligned_and_filtered.fasta",
        metadata="data/metadata.tsv",
    output:
        tree="results/{build}/tree.nwk",
        node_data="results/{build}/branch_lengths.json",
    params:
        root=lambda w: "best" if w.build == "genome" else "mid_point",
        strain_id=config["strain_id_field"],
        coalescent=config["refine"]["coalescent"],
        date_inference=config["refine"]["date_inference"],
        clock_filter_iqd=config["refine"]["clock_filter_iqd"],
    log:
        "logs/{build}/refine.txt",
    benchmark:
        "benchmarks/{build}/refine.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur refine \
            --tree {input.tree:q} \
            --alignment {input.alignment:q} \
            --root {params.root} \
            --metadata {input.metadata:q} \
            --output-tree {output.tree:q} \
            --output-node-data {output.node_data:q} \
            --metadata-id-columns {params.strain_id:q} \
            --timetree \
            --coalescent {params.coalescent:q} \
            --clock-rate 0.0006 \
            --date-confidence \
            --date-inference {params.date_inference:q} \
            --clock-filter-iqd {params.clock_filter_iqd:q} \
            --stochastic-resolve
        """
