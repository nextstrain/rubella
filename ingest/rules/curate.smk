"""
This part of the workflow handles the curation of data from NCBI

REQUIRED INPUTS:

    ndjson      = data/ncbi.ndjson

OUTPUTS:

    metadata    = results/metadata.tsv
    seuqences   = results/sequences.fasta

"""


rule fetch_general_geolocation_rules:
    output:
        general_geolocation_rules="data/general-geolocation-rules.tsv",
    params:
        geolocation_rules_url=config["curate"]["geolocation_rules_url"],
    log:
        "logs/fetch_general_geolocation_rules.txt",
    benchmark:
        "benchmarks/fetch_general_geolocation_rules.txt"
    shell:
        r"""
        curl {params.geolocation_rules_url:q} > {output.general_geolocation_rules:q} \
          2> {log:q}
        """


rule concat_geolocation_rules:
    input:
        general_geolocation_rules="data/general-geolocation-rules.tsv",
        local_geolocation_rules=config["curate"]["local_geolocation_rules"],
    output:
        all_geolocation_rules="data/all-geolocation-rules.tsv",
    log:
        "logs/concat_geolocation_rules.txt",
    benchmark:
        "benchmarks/concat_geolocation_rules.txt"
    shell:
        r"""
        cat {input.general_geolocation_rules:q} {input.local_geolocation_rules:q} \
          > {output.all_geolocation_rules:q} 2> {log:q}
        """


def format_field_map(field_map: dict[str, str]) -> str:
    """
    Format dict to `"key1"="value1" "key2"="value2"...` for use in shell commands.
    """
    return " ".join([f'"{key}"="{value}"' for key, value in field_map.items()])


rule curate:
    input:
        sequences_ndjson="data/ncbi.ndjson",
        all_geolocation_rules="data/all-geolocation-rules.tsv",
        annotations=config["curate"]["annotations"],
    output:
        metadata=temp("data/all_metadata_intermediate.tsv"),
        sequences="results/sequences.fasta",
    log:
        "logs/curate.txt",
    benchmark:
        "benchmarks/curate.txt"
    params:
        field_map=format_field_map(config["curate"]["field_map"]),
        strain_regex=config["curate"]["strain_regex"],
        strain_backup_fields=config["curate"]["strain_backup_fields"],
        date_fields=config["curate"]["date_fields"],
        expected_date_formats=config["curate"]["expected_date_formats"],
        genbank_location_field=config["curate"]["genbank_location_field"],
        articles=config["curate"]["titlecase"]["articles"],
        abbreviations=config["curate"]["titlecase"]["abbreviations"],
        titlecase_fields=config["curate"]["titlecase"]["fields"],
        authors_field=config["curate"]["authors_field"],
        authors_default_value=config["curate"]["authors_default_value"],
        abbr_authors_field=config["curate"]["abbr_authors_field"],
        annotations_id=config["curate"]["annotations_id"],
        id_field=config["curate"]["output_id_field"],
        sequence_field=config["curate"]["output_sequence_field"],
    shell:
        r"""
        (cat {input.sequences_ndjson:q} \
            | augur curate rename \
                --field-map {params.field_map} \
            | augur curate normalize-strings \
            | augur curate transform-strain-name \
                --strain-regex {params.strain_regex:q} \
                --backup-fields {params.strain_backup_fields:q} \
            | augur curate format-dates \
                --date-fields {params.date_fields:q} \
                --expected-date-formats {params.expected_date_formats:q} \
            | augur curate parse-genbank-location \
                --location-field {params.genbank_location_field:q} \
            | augur curate titlecase \
                --titlecase-fields {params.titlecase_fields:q} \
                --articles {params.articles:q} \
                --abbreviations {params.abbreviations:q} \
            | augur curate abbreviate-authors \
                --authors-field {params.authors_field:q} \
                --default-value {params.authors_default_value:q} \
                --abbr-authors-field {params.abbr_authors_field:q} \
            | augur curate apply-geolocation-rules \
                --geolocation-rules {input.all_geolocation_rules:q} \
            | augur curate apply-record-annotations \
                --annotations {input.annotations:q} \
                --id-field {params.annotations_id:q} \
                --output-metadata {output.metadata:q} \
                --output-fasta {output.sequences:q} \
                --output-id-field {params.id_field:q} \
                --output-seq-field {params.sequence_field:q}
        ) 2> {log:q}
        """


rule add_genbank_url:
    input:
        metadata="data/all_metadata_intermediate.tsv",
    output:
        metadata="data/all_metadata.tsv",
    log:
        "logs/add_genbank_url.txt",
    benchmark:
        "benchmarks/add_genbank_url.txt"
    shell:
        r"""
        csvtk mutate2 -t \
          -n url \
          -e '"https://www.ncbi.nlm.nih.gov/nuccore/" + $accession' \
          {input.metadata:q} > {output.metadata:q} 2> {log:q}
        """


rule subset_metadata:
    input:
        metadata="data/all_metadata.tsv",
    output:
        subset_metadata="results/metadata.tsv",
    params:
        metadata_fields=",".join(config["curate"]["metadata_columns"]),
    log:
        "logs/subset_metadata.txt",
    benchmark:
        "benchmarks/subset_metadata.txt"
    shell:
        r"""
        csvtk cut -t -f {params.metadata_fields:q} \
            {input.metadata:q} \
        > {output.subset_metadata:q} 2> {log:q}
        """
