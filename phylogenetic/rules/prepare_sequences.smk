"""
This part of the workflow prepares sequences for constructing the
phylogenetic tree.
"""
from augur.subsample import get_referenced_files


rule download:
    output:
        metadata="data/metadata.tsv.zst",
        sequences="data/sequences.fasta.zst",
    params:
        sequences_url="https://data.nextstrain.org/files/workflows/rubella/sequences.fasta.zst",
        metadata_url="https://data.nextstrain.org/files/workflows/rubella/metadata.tsv.zst",
    log:
        "logs/download.txt",
    benchmark:
        "benchmarks/download.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

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
    log:
        "logs/decompress.txt",
    benchmark:
        "benchmarks/decompress.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        zstd -d -c {input.sequences} > {output.sequences}
        zstd -d -c {input.metadata} > {output.metadata}
        """


rule subsample_genome:
    input:
        metadata = "data/metadata.tsv",
        sequences = "data/sequences.fasta",
        config = "results/genome/subsample_config.yaml",
        referenced_files = get_referenced_files(f"results/genome/subsample_config.yaml"),
    output:
        sequences = "results/genome/subsampled.fasta",
    params:
        strain_id = config["strain_id_field"],
    log:
        "logs/genome/subsample.txt",
    benchmark:
        "benchmarks/genome/subsample.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        augur subsample \
            --config {input.config} \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output-sequences {output.sequences}
        """


rule align_genome:
    input:
        sequences="results/genome/subsampled.fasta",
        reference=config["files"]["genome"]["reference"],
    output:
        alignment="results/genome/aligned_and_subsampled.fasta",
    threads: workflow.cores * 0.5
    log:
        "logs/genome/align_genome.txt",
    benchmark:
        "benchmarks/genome/align_genome.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur align \
            --sequences {input.sequences} \
            --output {output.alignment} \
            --nthreads {threads} \
            --fill-gaps
        """


rule align_and_extract_E1:
    input:
        sequences="data/sequences.fasta",
        reference=config["files"]["E1"]["reference"],
    output:
        alignment="results/E1/aligned.fasta",
    threads: workflow.cores * 0.5
    log:
        "logs/E1/filter_and_extract_E1.txt",
    benchmark:
        "benchmarks/genome/filter_and_extract_E1.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur align \
            --sequences {input.sequences:q} \
            --reference-sequence {input.reference:q} \
            --output {output.alignment:q} \
            --nthreads {threads} \
            --fill-gaps \
            --remove-reference
        """


rule subsample_E1:
    input:
        sequences = "results/E1/aligned.fasta",
        metadata = "data/metadata.tsv",
        config = "results/E1/subsample_config.yaml",
        referenced_files = get_referenced_files(f"results/E1/subsample_config.yaml"),
    output:
        sequences = "results/E1/aligned_and_subsampled.fasta",
    params:
        strain_id = config["strain_id_field"],
    log:
        "logs/E1/subsample.txt",
    benchmark:
        "benchmarks/E1/subsample.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        augur subsample \
            --config {input.config} \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output-sequences {output.sequences}
        """
