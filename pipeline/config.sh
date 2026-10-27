#!/bin/bash
# Shared settings for every analysis. Sourced by RUN_ME.sh, check.sh and status.sh.
# Change a path or account here, nowhere else.

CW_REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

PROJECT_ACCOUNT=project_2019675
PARTITION=small
MAIL_USER=eero.saarinen@helsinki.fi

# Current layout: outputs stay in the base directory, so existing results are
# where the scripts already expect them. Moving OUTPUTS elsewhere is a separate
# step (see docs/restructure-plan.md).
BASE=${CW_BASE:-/scratch/project_2019675/the_coffee_wrecks}
OUTPUTS=$BASE

REF=$BASE/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna
SAMPLES_TSV=$CW_REPO/data/samples/samples.tsv
