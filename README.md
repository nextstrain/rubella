# Nextstrain repository for rubella

TODO write me

## Installation

## Installation

Follow the [standard installation instructions][] for Nextstrain's
suite of software tools.

## Quick start

TODO write me

Further documentation is available at "[Running a pathogen workflow][]".

## Working on this repository

This repository is configured to use [pre-commit][] to help
automatically catch common coding errors and syntax issues with
changes before they are committed to the repo.

If you will be writing new code or otherwise working within this
repository, please do the following to get started:

1. install `pre-commit`, by running either `python -m pip install
   pre-commit` or `brew install pre-commit`, depending on your
   preferred package management solution
2. install the local git hooks by running `pre-commit install` from
   the root of the repository
3. when problems are detected, correct them in your local working tree
   before committing them.

Note that these pre-commit checks are also run in a GitHub Action when
changes are pushed to GitHub, so correcting issues locally will
prevent extra cycles of correction.

[Running a pathogen workflow]: https://docs.nextstrain.org/en/latest/tutorials/running-a-workflow.html
[pre-commit]: https://pre-commit.com
[standard installation instructions]: https://docs.nextstrain.org/en/latest/install.html
