"""
This part of the workflow collects the phylogenetic tree and annotations to
export a Nextstrain dataset.
"""


rule colors:
    input:
        color_schemes="defaults/color_schemes.tsv",
        color_orderings="defaults/color_orderings.tsv",
        #FIXME metadata = "data/metadata.tsv",
        metadata="../ingest/results/metadata.tsv",
    output:
        colors="data/colors.tsv",
    shell:
        r"""
        python3 scripts/assign-colors.py \
          --color-schemes {input.color_schemes:q} \
          --ordering {input.color_orderings:q} \
          --metadata {input.metadata:q} \
          --output {output.colors:q}
        """


rule export:
    """Exporting data files for for auspice"""
    input:
        tree="results/{build}/tree.nwk",
        #FIXME metadata = "data/metadata.tsv",
        metadata="../ingest/results/metadata.tsv",
        branch_lengths="results/{build}/branch_lengths.json",
        traits="results/{build}/traits.json",
        nt_muts="results/{build}/nt_muts.json",
        aa_muts="results/{build}/aa_muts.json",
        colors="data/colors.tsv",
        auspice_config=lambda w: config["files"][w.build]["auspice_config"],
        description=config["files"]["description"],
    output:
        auspice_json="auspice/rubella_{build}.json",
    params:
        metadata_columns=config["export"]["metadata_columns"],
        strain_id=config["strain_id_field"],
    log:
        "logs/{build}/export.txt",
    benchmark:
        "benchmarks/{build}/export.txt"
    shell:
        r"""
        augur export v2 \
            --tree {input.tree:q} \
            --metadata {input.metadata:q} \
            --node-data {input.branch_lengths:q} {input.traits:q} {input.nt_muts:q} {input.aa_muts:q} \
            --colors {input.colors:q} \
            --auspice-config {input.auspice_config:q} \
            --description {input.description:q} \
            --output {output.auspice_json:q} \
            --metadata-columns {params.metadata_columns} \
            --metadata-id-columns {params.strain_id:q} \
            --include-root-sequence-inline \
          2> {log:q}
        """


rule tip_frequencies:
    """
    Estimating KDE frequencies for tips
    """
    input:
        tree="results/{build}/tree.nwk",
        #FIXME metadata = "data/metadata.tsv"
        metadata="../ingest/results/metadata.tsv",
    output:
        tip_freq="auspice/rubella_{build}_tip-frequencies.json",
    params:
        strain_id=config["strain_id_field"],
        min_date=config["tip_frequencies"]["min_date"],
        max_date=config["tip_frequencies"]["max_date"],
        narrow_bandwidth=config["tip_frequencies"]["narrow_bandwidth"],
        wide_bandwidth=config["tip_frequencies"]["wide_bandwidth"],
    shell:
        r"""
        augur frequencies \
            --method kde \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --min-date {params.min_date} \
            --max-date {params.max_date} \
            --narrow-bandwidth {params.narrow_bandwidth} \
            --wide-bandwidth {params.wide_bandwidth} \
            --output {output.tip_freq}
        """
