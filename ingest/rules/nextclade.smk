"""
This part of the workflow handles running Nextclade on the curated metadata
and sequences.
"""

DATASET_NAME = config["nextclade"]["dataset_name"]


# FIXME uncomment once
# https://github.com/nextstrain/nextclade_data/pull/302 is merged
# rule get_nextclade_dataset:
#     """Download Nextclade dataset"""
#     output:
#         dataset=f"data/nextclade_data/{DATASET_NAME}.zip",
#     params:
#         dataset_name=DATASET_NAME,
#     shell:
#         r"""
#         nextclade3 dataset get \
#             --name={params.dataset_name:q} \
#             --output-zip={output.dataset} \
#             --verbose
#         """


rule run_nextclade:
    input:
        # FIXME remove once
        # https://github.com/nextstrain/nextclade_data/pull/302
        # is merged
        dataset="defaults/dataset.zip",
        #dataset=f"data/{DATASET_NAME}.zip",
        sequences="results/sequences.fasta",
    output:
        nextclade="results/nextclade.tsv",
        alignment="results/alignment.fasta",
    log:
        "logs/run_nextclade.txt",
    benchmark:
        "benchmarks/run_nextclade.txt"
    shell:
        r"""
        nextclade3 run \
            {input.sequences} \
            --input-dataset {input.dataset} \
            --output-tsv {output.nextclade} \
            --output-fasta {output.alignment} \
          &> {log:q}
        """


rule nextclade_metadata:
    input:
        nextclade="results/nextclade.tsv",
    output:
        nextclade_metadata=temp("results/nextclade_metadata.tsv"),
    params:
        nextclade_id_field=config["nextclade"]["id_field"],
        nextclade_field_map=[
            f"{old}={new}" for old, new in config["nextclade"]["field_map"].items()
        ],
        nextclade_fields=",".join(config["nextclade"]["field_map"].values()),
    log:
        "logs/nextclade_metadata.txt",
    benchmark:
        "benchmarks/nextclade_metadata.tsv"
    shell:
        r"""
        augur curate rename \
            --metadata {input.nextclade:q} \
            --id-column {params.nextclade_id_field:q} \
            --field-map {params.nextclade_field_map:q} \
            --output-metadata - \
          | csvtk cut --tabs --fields {params.nextclade_fields:q} \
        > {output.nextclade_metadata:q} 2> {log:q}
        """


rule join_metadata_and_nextclade:
    input:
        metadata="data/subset_metadata.tsv",
        nextclade_metadata="results/nextclade_metadata.tsv",
    output:
        metadata="results/metadata.tsv",
    params:
        metadata_id_field=config["curate"]["output_id_field"],
        nextclade_id_field=config["nextclade"]["id_field"],
    log:
        "logs/join_metadata_and_nextclade.txt",
    benchmark:
        "benchmarks/join_metadata_and_nextclade.txt"
    shell:
        r"""
        augur merge \
            --metadata \
                metadata={input.metadata:q} \
                nextclade={input.nextclade_metadata:q} \
            --metadata-id-columns \
                metadata={params.metadata_id_field:q} \
                nextclade={params.nextclade_id_field:q} \
            --output-metadata {output.metadata:q} \
            --no-source-columns \
        &> {log:q}
        """
