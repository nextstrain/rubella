"""
This part of the workflow collects the phylogenetic tree and
annotations to export a Nextstrain dataset.
"""


rule export:
    input:
        tree="results/tree.nwk",
        metadata="data/metadata.tsv",
        branch_lengths="results/branch_lengths.json",
        clades="results/clades.json",
        nt_muts="results/nt_muts.json",
        aa_muts="results/aa_muts.json",
        colors=config["files"]["colors"],
        auspice_config=config["files"]["auspice_config"],
    output:
        auspice_json=config["files"]["auspice_json"],
    params:
        strain_id=config["strain_id_field"],
        metadata_columns=config["export"]["metadata_columns"],
    log:
        "logs/export.txt",
    benchmark:
        "benchmarks/export.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur export v2 \
            --tree {input.tree:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --node-data {input.branch_lengths} {input.nt_muts} {input.aa_muts} {input.clades} \
            --colors {input.colors:q} \
            --metadata-columns {params.metadata_columns} \
            --auspice-config {input.auspice_config:q} \
            --include-root-sequence-inline \
            --output {output.auspice_json:q}
        """
