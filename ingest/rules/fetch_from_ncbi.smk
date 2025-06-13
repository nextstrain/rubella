"""
This part of the workflow handles fetching sequences and metadata from NCBI.

REQUIRED INPUTS:

    None

OUTPUTS:

    ndjson  = data/ncbi.ndjson
    genbank = data/entrez.gb

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
        exec &> >(tee {log:q})

        datasets download virus genome taxon {params.ncbi_taxon_id:q} \
            --no-progressbar \
            --filename {output.dataset_package:q}
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
        exec &> >(tee {log:q})

        unzip -jp {input.dataset_package:q} \
            ncbi_dataset/data/genomic.fna \
          > {output.ncbi_dataset_sequences:q}
        """


rule format_ncbi_dataset_metadata:
    input:
        dataset_package="data/ncbi_dataset.zip",
    output:
        ncbi_dataset_metadata_tsv="data/ncbi_dataset_metadata.tsv",
    params:
        ncbi_datasets_fields=",".join(config["ncbi_datasets_fields"]),
    log:
        "logs/format_ncbi_dataset_report.txt",
    benchmark:
        "benchmarks/format_ncbi_dataset_report.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        dataformat tsv virus-genome \
            --package {input.dataset_package:q} \
            --fields {params.ncbi_datasets_fields:q} \
            --elide-header \
            | csvtk add-header -t -n {params.ncbi_datasets_fields:q} \
            | csvtk rename -t -f accession -n accession_version \
            | csvtk mutate -t -f accession_version -n accession -p "^(.+?)\." --at 1 \
            | csvtk mutate2 -t -n url -e '"https://www.ncbi.nlm.nih.gov/nuccore/" + $accession' \
          > {output.ncbi_dataset_metadata_tsv:q}
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
        exec &> >(tee {log:q})

        vendored/fetch-from-ncbi-entrez \
            --term {params.term:q} \
            --output {output.genbank:q}
        """


rule extract_genbank_genotypes:
    input:
        genbank="data/entrez.gb",
    output:
        genbank_annotations_tsv="data/genbank-annotations.tsv",
    log:
        "logs/extract_genbank_genotypes.txt",
    benchmark:
        "benchmarks/extract_genbank_genotypes.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        ./scripts/extract-genbank-annotations.py \
            --genbank {input.genbank:q} \
          > {output.genbank_annotations_tsv:q}
        """


rule merge_genbank_annotations:
    input:
        main_metadata="data/ncbi_dataset_metadata.tsv",
        geno_metadata="data/genbank-annotations.tsv",
    output:
        metadata=temp("data/metadata_intermediate.tsv"),
    params:
        metadata_id_column=config["curate"]["metadata_id_column"],
    log:
        "logs/merge_genbank_annotations.txt",
    benchmark:
        "benchmarks/merge_genbank_annotations.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur merge \
          --metadata main={input.main_metadata:q} geno={input.geno_metadata:q} \
          --metadata-id-columns {params.metadata_id_column:q} \
          --output-metadata {output.metadata:q}
        """


rule format_ncbi_datasets_ndjson:
    input:
        ncbi_dataset_sequences="data/ncbi_dataset_sequences.fasta",
        intermediate_metadata_tsv="data/metadata_intermediate.tsv",
    output:
        ndjson="data/ncbi.ndjson",
    log:
        "logs/format_ncbi_datasets_ndjson.txt",
    benchmark:
        "benchmarks/format_ncbi_datasets_ndjson.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur curate passthru \
            --metadata {input.intermediate_metadata_tsv:q} \
            --fasta {input.ncbi_dataset_sequences:q} \
            --seq-id-column accession_version \
            --seq-field sequence \
            --unmatched-reporting warn \
            --duplicate-reporting warn \
          > {output.ndjson:q}
        """
