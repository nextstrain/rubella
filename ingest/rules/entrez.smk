

rule fetch_entrez:
    params:
        term=config["entrez_term"]
    output:
        gb="data/entrez.gb"
    # Allow retries in case of network errors
    retries: 3
    log:
        "logs/fetch_entrez.txt",
    benchmark:
        "benchmarks/fetch_entrez.txt"
    shell:
        r"""
        vendored/fetch-from-ncbi-entrez --term {params.term:q} --output {output.gb} > {log:q} 2>&1
        """

rule genbank_to_json:
    # This needs the `bio` CLI <https://www.bioinfo.help/> as well as jq
    input:
        gb = rules.fetch_entrez.output.gb
    output:
        ndjson = "data/entrez.ndjson"
    shell:
        r"""
        bio json {input.gb} \
            | jq -c '.[] | {{accession: .record.accessions[0], entrez: .}}' \
            > {output.ndjson}
        """