"""
This part of the workflow prepares sequences for constructing the
phylogenetic tree.
"""


rule download:
    output:
        metadata="data/metadata.tsv.zst",
        sequences="data/sequences.fasta.zst",
    params:
        sequences_url="https://data.nextstrain.org/files/workflows/rubella/sequences.fasta.zst",
        metadata_url="https://data.nextstrain.org/files/workflows/rubella/metadata.tsv.zst",
    shell:
        r"""
        curl -fsSL --compressed {params.sequences_url:q} --output {output.sequences}
        curl -fsSL --compressed {params.metadata_url:q} --output {output.metadata}
        """


rule decompress:
    input:
        sequences="data/sequences.fasta.zst",
        metadata="data/metadata.tsv.zst",
    output:
        sequences="data/sequences.fasta",
        metadata="data/metadata.tsv",
    shell:
        r"""
        zstd -d -c {input.sequences} > {output.sequences}
        zstd -d -c {input.metadata} > {output.metadata}
        """


rule align_and_extract_E1:
    input:
        sequences="data/sequences.fasta",
        reference=config["files"]["reference_E1_fasta"],
    output:
        sequences="results/sequences.fasta",
    params:
        min_length=config["align_and_extract_E1"]["min_length"],
        min_seed_cover=config["align_and_extract_E1"]["min_seed_cover"],
    log:
        "logs/align_and_extract_E1.txt",
    benchmark:
        "benchmarks/align_and_extract_E1.txt"
    threads: workflow.cores
    shell:
        r"""
        touch {log:q} && \
        nextclade3 run \
            --jobs {threads:q} \
            --input-ref {input.reference:q} \
            --output-fasta {output.sequences:q} \
            --min-seed-cover {params.min_seed_cover:q} \
            --min-length {params.min_length:q} \
            --silent \
            {input.sequences:q} \
          &> {log:q}
        """


rule filter:
    input:
        include=config["files"]["include"],
        metadata="data/metadata.tsv",
        sequences="results/sequences.fasta",
    output:
        sequences="results/aligned.fasta",
    params:
        strain_id=config["strain_id_field"],
    log:
        "logs/filter.txt",
    benchmark:
        "benchmarks/filter.txt"
    shell:
        r"""
        augur filter \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --exclude-all \
            --include {input.include:q} \
            --output-sequences {output.sequences:q} \
          &> {log:q}
        """
