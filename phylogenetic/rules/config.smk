"""
This part of the workflow deals with configuration.

OUTPUTS:

    results/run_config.yaml
"""
def main():
    write_subsample_config()
    write_config("results/run_config.yaml")


def write_subsample_config():
    # TODO: Support custom build names in the workflow and infer from
    # config["builds"].
    for build in ["genome", "E1"]:
        if "custom_subsample" in config:
            section = ["custom_subsample", build]
        else:
            section = ["subsample", build]
        write_config(f"results/{build}/subsample_config.yaml", section=section)


try:
    main()
except InvalidConfigError as e:
    print(f"ERROR: {e}", file=sys.stderr)
    exit(1)
