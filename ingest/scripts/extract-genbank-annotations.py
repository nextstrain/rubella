#! /usr/bin/env python
"""
Parses file with multiple GenBank records (provided via --genbank
argument) to extract TSV-formatted accession, genotype, and best
available date. Outputs TSV to STDOUT.

Intended to be merged with other TSV-formatted data in subsequent
`augur merge` step in workflow.
"""

import argparse
import csv
from datetime import date
from dateutil import parser
import os
from pathlib import Path
import re
import sys

from Bio import SeqIO

# "official" WHO sample names for Rubella look like
# 'RVi/Minsk.BLR/24.04/1[1E]' or 'RVs/Rouen.FRA/97[1E]'
#
# When present in GenBank records, they are found in the "source"
# feature, in a `/strain` or `/isolate` annotation.
#
# If an "official" strain name is present, the first two letters will
# always be "RV"; the third letter will be an 'i' or 's' (indicating
# whether the RNA was derived from a viral isolate or a clinical
# sample, correspondingly). The remainder of the genotype is
# delineated by `/` characters.
#
# The next `/`-delineated section contains geographical information
# for the sample: the city or state where the case occurred (only
# ASCII characters (including spaces) allowed), followed by a ISO-3
# country code; these two pieces of information are separated by a `.`.
#
# The next `/`-delineated section contains the date of onset of
# disease (i.e., rash appearance, or sample collection date when rash
# appearance date is unknown, or the date of sample receipt by the lab
# if collection date is unknown), encoded as the "epiweek" followed by
# a `.`, followed by a 2-digit year. Empirically, sometimes the
# epiweek value is absent and only a year is present; additionally,
# sometimes the year is given as a 4-digit year instead of 2.
# Pragmatically, year values less than 30 will be assumed to be in
# the 2000s; values greater than 30 will be assumed to be in the
# 1900s.
#
# If there are multiple samples that are not distinguished by the
# above rules, an additional monotonically-increasing integer is
# appended after the trailing `/` character. Note that, when present,
# this additional disambiguation character is NOT followed by an
# additional `/` delimiter.
#
# The WHO genotype designation, if present, will be found after all
# the above fields, in square brackets (e.g., `[2B]`)
#
# There may also be a trailing designation, usually in parentheses,
# indicating the sample arises from an individual with congenital
# rubella syndrome (CRS), newborns with a congenital rubella infection
# (CRI), or a vaccine-derived strain (VAC). For cases marked with CRS
# or CRI, the geographic localization is the place of birth and onset
# date of disease is the date of birth.
#
# Samples may also have a "collection_date" annotation in the "source"
# feature. If that is present and is not just a 4-digit year, this
# script will output that for the date field; otherwise, if a genotype
# with an epiweek and a year is present, the script will parse the
# epiweek and year into a year-month date with an ambiguous day
# component (e.g., 2020-01-XX for a epidate of `01.20`). If both
# "collection_date" and the epi-date consist of only a year, the
# script will output the "collection_date" year.
#
# In cases where the script can detect something that looks like a
# genotype in the sample name, it will extract and report that. The
# genotypes reported are limited to those defined by WHO (i.e., 1a,
# 1B-1J, 2A-2C); they are further normalize to the set of provisional
# and accepted genotypes given in the [2013 WHO Rubella nomenclature
# publication][], so a 1A genotype will be normalized to 1a; a 1j
# genotype will be normalized to 1J.
#
# [2013 WHO Rubella nomenclature publication]: https://www.who.int/publications/i/item/WER8832
#
# Occasionally, neither the strain and isolation annotations will
# contain anything that can be parsed as an "offical" WHO genotype,
# but there will be a `/note` annotation that looks like "genotype 1a"
# or "Genotype: 2B". In that case the script will extract and return
# the genotype, normalized as described above.


def main():
    args = _parse_args()

    tsv_writer = csv.writer(sys.stdout, delimiter="\t")
    tsv_writer.writerow(
        [
            "accession",
            "strain",
            "date",
            "genbank_genotype",
            "clade",
        ]
    )

    for record in SeqIO.parse(args.genbank, "genbank"):
        accession = record.annotations["accessions"][0]
        deposit_year = parser.parse(record.annotations["date"]).year

        for f in record.features:
            if f.type == "source":
                results = _parse_source_feature(f.qualifiers)

                tsv_writer.writerow(
                    [
                        accession,
                        results["strain"],
                        _determine_best_date(
                            results,
                            accession,
                            deposit_year,
                        ),
                        results["genotype"],
                        "",
                    ]
                )


def _determine_best_date(results, accession, deposit_year):
    """
    Extract the best date from what is available in `collection_date` and
    the epi-date from the genotype, according to the following rules:

    * Prefer the `collection_date`, if more specific than a simple bare
      four-digit year
    * Otherwise, use epi-date if both week and year parts are present
    * Otherwise, if `collection_date` contains a four-digit year, use
      that
    * Otherwise, if the epi-date consists of only a year use that
    * Finally, return the empty string

    The `deposit_year` argument is used to validate the epi-date, if it
    is to be used — if the deposit year is earlier than the calculated
    epi-year, an error will be thrown.

    Notes/context on epiweek calculations:
    https://bedfordlab.slack.com/archives/C01LCTT7JNN/p1718643444417379
    """
    epiyear_error_msg = None
    # strains that are known to have funky epi-dates or other issues, that are
    # excluded from analysis during the phylogenetic build
    known_funky_genotypes = _read_samples_excluded_from_phylogenetic_build()

    # so we only have to check this once…
    if results["epiyear"] and int(results["epiyear"]) > deposit_year:
        if accession not in known_funky_genotypes:
            epiyear_error_msg = (
                f"parsed epi-year {results['epiyear']} > {deposit_year} "
                + f"for strain {results['strain']}/{accession} — not possible!"
            )

    if results["collection_date"]:
        # if we have a collection date and it's more than just a year, use that
        if len(results["collection_date"]) > 4:
            return results["collection_date"]

        # otherwise if we have an epiweek and an epiyear, turn that into a date and use it
        elif results["epiweek"] and results["epiyear"] and int(results["epiweek"]) > 0:
            if epiyear_error_msg is not None:
                raise ValueError(epiyear_error_msg)

            return _determine_epidate(
                int(results["epiweek"]),
                int(results["epiyear"]),
            )

        # otherwise, use the collection date
        else:
            return f"{results['collection_date']}-XX-XX"

    # if there's no collection date but we have epiweek and epiyear,
    # turn that into a date and use it
    elif results["epiweek"] and results["epiyear"] and int(results["epiweek"]) > 0:
        if epiyear_error_msg is not None:
            raise ValueError(epiyear_error_msg)

        return _determine_epidate(
            int(results["epiweek"]),
            int(results["epiyear"]),
        )

    # otherwise, if there's no collection date and only an epiyear,
    # use the epiyear
    elif results["epiyear"]:
        if epiyear_error_msg is not None:
            raise ValueError(epiyear_error_msg)

        return f"{results['epiyear']}-XX-XX"

    # …if we get here, we give up
    else:
        return ""


def _determine_epidate(week, year):
    """
    Convert a WHO epi-week into an ISO week and return a month-year
    date (e.g., 2025-01-XX) corresponding to the first day of that ISO
    week.

    WHO epi-week one begins with the first Monday of the year.

    ISO week one begins with the first Monday of the first week of the
    year that has at least 4 days (i.e., the first week of the year
    that contains a Thursday).

    This means that if the first day of the year is a Sunday, Monday,
    Friday, or Saturday, the WHO epi-week and the ISO week numbers for
    the year are the same.

    If the first day of the year is a Tuesday, Wednesday, or Thursday,
    the WHO epi-week number is consistently one lower than the ISO week.
    """
    jan_one_weekday = date(year, 1, 1).weekday()

    if jan_one_weekday > 0 and jan_one_weekday < 4:
        # if this is WHO epi-week one, it's actually the last ISO week
        # of the previous year…
        if week == 1:
            year = year - 1
            week = 52  # _might_ actually be 53, but be we only care about month in the end so going to 52 will DTRT
        # …otherwise it's just one week less
        else:
            week = week - 1

    # and then turn that into an ambigious-day datestring
    return date.fromisocalendar(year, week, 1).strftime("%Y-%m-XX")


def _normalize_year(year):
    """
    Heuristically convert a two-digit year into a four-digit one.
    """
    if int(year) <= 30:
        return int(year) + 2000
    elif int(year) > 30:
        return int(year) + 1900
    else:
        raise ValueError(
            f"YEAR {year!r} CANNOT BE NORMALIZED; THIS SHOULD BE IMPOSSIBLE"
        )


def _parse_args():
    parser = argparse.ArgumentParser(
        description="Extract genotype and epiweek date range from GenBank records."
    )
    parser.add_argument("--genbank", required=True, help="GenBank record file to parse")

    return parser.parse_args()


def _parse_date(date):
    """
    Heuristically turn a "epi-date" from a WHO genotype into a dict
    with "epiweek" and "epiyear" keys, based on different formats
    observed in the input dataset.
    """
    # case #1: actually follows WHO spec: two digit epiweek, followed
    # by dot, followed by two digit year
    match = re.search(r"^([0-9]{1,2})\.([0-9]{2})", date)
    if match:
        return {
            "epiweek": match.group(1),
            "epiyear": str(_normalize_year(match.group(2))),
        }

    # case #2: kinda WHO spec but uses four digit year
    match = re.search(r"^([0-9]{1,2})\.([0-9]{4})$", date)
    if match:
        return {"epiweek": match.group(1), "epiyear": match.group(2)}

    # case #3: if there are only two digits, maybe with a leading `.`
    # or maybe not, we assume it's a year
    match = re.search(r"^.?([0-9]{2})", date)
    if match:
        return {"epiweek": "", "epiyear": str(_normalize_year(match.group(1)))}

    return {"epiweek": "", "epiyear": ""}


def _parse_genotype(maybe_genotype):
    """
    Given a string that may contain a rubella genotype, extract the
    genotype, normalize it to accepted WHO format, and return it (or
    return the empty string if no genotype is found).
    """
    match = re.search(r"([12][aAbBcCdDeEfFgGhHiIjJ])", maybe_genotype)

    if match:
        genotype = match.group(1)
        return genotype.upper()

    return ""


def _parse_source_feature(qualifiers):
    """
    Given a set of qualifiers from the "source" feature of a GenBank
    record, attempt to extract and return the "collection_date",
    "epiweek" and "epiyear" extracted from WHO strain name, and
    "genotype" extracted also extracted from the WHO strain name.

    Results are returned as a dict with keys named above; if values
    cannot be extracted, the dict will have empty string values.
    """
    results = {
        "strain": "",
        "collection_date": "",
        "epiweek": "",
        "epiyear": "",
        "genotype": "",
    }

    # NOTE: SeqIO.parse turns all the source features into single element
    # lists, which is why all the `.get()` calls below append a `[0]`

    # extract the collection date, if it's present
    results["collection_date"] = qualifiers.get("collection_date", [""])[0]

    # Try to parse genotype and epidate, first from `strain`, and then
    # from `isolate` only if `strain` is not present. This ordering is
    # because, from empirical inspection, when both are present,
    # strain contains the WHO strain designation and isolate does not
    # — but when strain is missing, sometimes isolate has the WHO
    # strain name.
    isolate = qualifiers.get("isolate", [""])[0]
    strain = qualifiers.get("strain", [""])[0]

    if strain:
        _parse_strain_name(strain, results)
    elif isolate:
        _parse_strain_name(isolate, results)

    # if we didn't find a genotype in the strain or isolate, see if
    # it's in the note
    if not results["genotype"]:
        note = qualifiers.get("note", [""])[0]
        results["genotype"] = _parse_genotype(note)

    return results


def _parse_strain_name(name, results):
    """
    Given a putative WHO strain name and a results dict, attempt to
    extract epiweek, epiyear, and genotype from the strain name, and
    update the provided results dict accordingly.
    """
    clean_name = name.replace("CRS", "").replace("CRI", "")

    if re.match(r"^RV[is]/", clean_name):
        results["strain"] = name

        location = ""
        date = ""
        genotype = ""

        parts = clean_name.split("/", 3)[1:]
        if len(parts) > 2:
            location, date, genotype = parts
        elif len(parts) == 2:
            location, date_and_genotype = parts
            if "[" in date_and_genotype:
                date, genotype = date_and_genotype.split("[", 1)
            else:
                date = date_and_genotype

        parsed_date = _parse_date(date)
        results["epiweek"] = parsed_date["epiweek"]
        results["epiyear"] = parsed_date["epiyear"]

        results["genotype"] = _parse_genotype(genotype)


def _read_samples_excluded_from_phylogenetic_build():
    dropped_samples_file = (
        Path(os.path.dirname(os.path.realpath(__file__)))
        / ".."
        / ".."
        / "phylogenetic"
        / "defaults"
        / "dropped_strains.txt"
    )
    with open(dropped_samples_file, "r") as dropped_fh:
        dropped_samples = dropped_fh.read().splitlines()

    return [line.split("#")[0].rstrip() for line in dropped_samples]


main()
