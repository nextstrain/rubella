"""
This part of the workflow prepares sequences for constructing the
phylogenetic tree.
"""

# FIXME once the ingest build is finalized and data is uploaded to S3,
# this rule should be uncommented, and the location of metadata.tvs
# and sequences.fasta in various rules should be adjusted.
# rule download:
#     output:
#         metadata="data/metadata.tsv.zst",
#         sequences="data/sequences.fasta.zst",
#     params:
#         sequences_url="https://data.nextstrain.org/files/workflows/yellow-fever/sequences.fasta.zst",
#         metadata_url="https://data.nextstrain.org/files/workflows/yellow-fever/metadata.tsv.zst",
#     shell:
#         r"""
#         curl -fsSL --compressed {params.sequences_url:q} --output {output.sequences}
#         curl -fsSL --compressed {params.metadata_url:q} --output {output.metadata}
#         """


# FIXME once the ingest build is finalized and data is uploaded to S3,
# this rule should be uncommented, and the location of metadata.tvs
# and sequences.fasta in various rules should be adjusted.
# rule decompress:
#     input:
#         sequences="data/sequences.fasta.zst",
#         metadata="data/metadata.tsv.zst",
#     output:
#         sequences="data/sequences.fasta",
#         metadata="data/metadata.tsv",
#     shell:
#         r"""
#         zstd -d -c {input.sequences} > {output.sequences}
#         zstd -d -c {input.metadata} > {output.metadata}
#         """


rule filter_genome:
    input:
        exclude=config["files"]["genome"]["exclude"],
        include=config["files"]["genome"]["include"],
        #FIXME metadata = "data/metadata.tsv",
        #FIXME sequences = "data/sequences.fasta"
        metadata="../ingest/results/metadata.tsv",
        sequences="../ingest/results/sequences.fasta",
    output:
        sequences="results/genome/filtered.fasta",
    params:
        group_by=config["filter"]["group_by"],
        min_length=config["filter"]["genome"]["min_length"],
        sequences_per_group=config["filter"]["genome"]["sequences_per_group"],
        strain_id=config["strain_id_field"],
    log:
        "logs/genome/filter_genome.txt",
    benchmark:
        "benchmarks/genome/filter_genome.txt"
    shell:
        r"""
        augur filter \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --exclude {input.exclude:q} \
            --include {input.include:q} \
            --output {output.sequences:q} \
            --group-by {params.group_by} \
            --sequences-per-group {params.sequences_per_group:q} \
            --min-length {params.min_length:q} \
          2> {log:q}
        """


rule align_genome:
    input:
        sequences="results/genome/filtered.fasta",
        reference=config["files"]["genome"]["reference"],
    output:
        alignment="results/genome/aligned_and_filtered.fasta",
    log:
        "logs/genome/align_genome.txt",
    benchmark:
        "benchmarks/genome/align_genome.txt"
    shell:
        r"""
        augur align \
            --sequences {input.sequences} \
            --output {output.alignment} \
            --fill-gaps \
          2> {log:q}
        """


rule align_and_extract_E1:
    input:
        #FIXME sequences = "data/sequences.fasta"
        sequences="../ingest/results/sequences.fasta",
        reference=config["files"]["E1"]["reference"],
    output:
        alignment="results/E1/aligned.fasta",
    log:
        "logs/E1/filter_and_extract_E1.txt",
    benchmark:
        "benchmarks/genome/filter_and_extract_E1.txt"
    shell:
        r"""
        augur align \
            --sequences {input.sequences:q} \
            --reference-sequence {input.reference:q} \
            --output {output.alignment:q} \
            --fill-gaps \
            --remove-reference \
          2> {log:q}
        """


rule filter_E1:
    input:
        sequences="results/E1/aligned.fasta",
        #FIXME metadata = "data/metadata.tsv",
        metadata="../ingest/results/metadata.tsv",
        exclude=config["files"]["E1"]["exclude"],
        include=config["files"]["E1"]["include"],
    output:
        sequences="results/E1/aligned_and_filtered.fasta",
    params:
        strain_id=config["strain_id_field"],
        group_by=config["filter"]["group_by"],
        sequences_per_group=config["filter"]["E1"]["sequences_per_group"],
        min_length=config["filter"]["E1"]["min_length"],
    log:
        "logs/E1/filter_E1.txt",
    benchmark:
        "benchmarks/E1/filter_E1.txt"
    shell:
        r"""
        augur filter \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --exclude {input.exclude:q} \
            --include {input.include:q} \
            --output {output.sequences:q} \
            --metadata-id-columns {params.strain_id:q} \
            --group-by {params.group_by} \
            --sequences-per-group {params.sequences_per_group:q} \
            --min-length {params.min_length:q} \
          2> {log:q}
        """
