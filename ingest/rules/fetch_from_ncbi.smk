"""
This part of the workflow handles fetching sequences and metadata from NCBI.

REQUIRED INPUTS:

    None

OUTPUTS:

    ndjson  = data/ncbi.ndjson
    genbank = data/entrez.gb

"""


rule fetch_ncbi_entrez_data:
    params:
        term=config["entrez_search_term"],
    output:
        genbank="data/entrez.gb",
    # Allow retries in case of network errors
    retries: 5
    log:
        "logs/fetch_ncbi_entrez_data.txt",
    benchmark:
        "benchmarks/fetch_ncbi_entrez_data.txt"
    shell:
        r"""
        vendored/fetch-from-ncbi-entrez \
            --term {params.term:q} \
            --output {output.genbank:q}
          2> {log:q}
        """


rule fetch_ncbi_dataset_package:
    params:
        ncbi_taxon_id=config["ncbi_taxon_id"],
    output:
        dataset_package=temp("data/ncbi_dataset.zip"),
    # Allow retries in case of network errors
    retries: 5
    log:
        "logs/fetch_ncbi_dataset_package.txt",
    benchmark:
        "benchmarks/fetch_ncbi_dataset_package.txt"
    shell:
        r"""
        datasets download virus genome taxon {params.ncbi_taxon_id:q} \
            --no-progressbar \
            --filename {output.dataset_package:q} \
          2> {log:q}
        """


rule extract_ncbi_dataset_sequences:
    input:
        dataset_package="data/ncbi_dataset.zip",
    output:
        ncbi_dataset_sequences=temp("data/ncbi_dataset_sequences.fasta"),
    log:
        "logs/extract_ncbi_dataset_sequences.txt",
    benchmark:
        "benchmarks/extract_ncbi_dataset_sequences.txt"
    shell:
        r"""
        unzip -jp {input.dataset_package:q} \
            ncbi_dataset/data/genomic.fna \
          > {output.ncbi_dataset_sequences:q} 2> {log:q}
        """


rule format_ncbi_dataset_report:
    input:
        dataset_package="data/ncbi_dataset.zip",
    output:
        ncbi_dataset_tsv=temp("data/ncbi_dataset_report.tsv"),
    params:
        ncbi_datasets_fields=",".join(config["ncbi_datasets_fields"]),
    log:
        "logs/format_ncbi_dataset_report.txt",
    benchmark:
        "benchmarks/format_ncbi_dataset_report.txt"
    shell:
        r"""
        dataformat tsv virus-genome \
            --package {input.dataset_package:q} \
            --fields {params.ncbi_datasets_fields:q} \
            --elide-header \
            | csvtk add-header -t -n {params.ncbi_datasets_fields:q} \
            | csvtk rename -t -f accession -n accession_version \
            | csvtk -t mutate -f accession_version -n accession -p "^(.+?)\." --at 1 \
          > {output.ncbi_dataset_tsv:q} 2> {log:q}
        """


rule format_ncbi_datasets_ndjson:
    input:
        ncbi_dataset_sequences="data/ncbi_dataset_sequences.fasta",
        ncbi_dataset_tsv="data/ncbi_dataset_report.tsv",
    output:
        ndjson="data/ncbi.ndjson",
    log:
        "logs/format_ncbi_datasets_ndjson.txt",
    benchmark:
        "benchmarks/format_ncbi_datasets_ndjson.txt"
    shell:
        r"""
        augur curate passthru \
            --metadata {input.ncbi_dataset_tsv:q} \
            --fasta {input.ncbi_dataset_sequences:q} \
            --seq-id-column accession_version \
            --seq-field sequence \
            --unmatched-reporting warn \
            --duplicate-reporting warn \
          > {output.ndjson:q} 2> {log:q}
        """
