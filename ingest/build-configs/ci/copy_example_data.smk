rule copy_example_ncbi_data:
    input:
        ncbi_dataset="example-data/ncbi_dataset.zip",
    output:
        ncbi_dataset=temp("data/ncbi_dataset.zip"),
    shell:
        r"""
        cp -f {input.ncbi_dataset} {output.ncbi_dataset}
        """


# force this rule over NCBI data fetch
ruleorder: copy_example_ncbi_data > fetch_ncbi_dataset_package


rule copy_example_geolocation_rules:
    input:
        general_geolocation_rules="example-data/general-geolocation-rules.tsv",
    output:
        general_geolocation_rules="data/general-geolocation-rules.tsv",
    shell:
        r"""
        cp -f {input.general_geolocation_rules} {output.general_geolocation_rules}
        """


# force this rule over downloading geolocation rules
ruleorder: copy_example_geolocation_rules > fetch_general_geolocation_rules
