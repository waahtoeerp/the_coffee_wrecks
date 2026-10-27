#!/bin/bash
# Shared settings for every analysis. Sourced by RUN_ME.sh, check.sh, status.sh,
# the stage scripts and the reference fetch. Change a path or account here only.
#
# Sourced from job scripts by absolute path: SLURM copies batch scripts to a
# spool directory, so do not derive paths from BASH_SOURCE inside a job.

CW_REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

PROJECT_ACCOUNT=project_2019675
PARTITION=small
MAIL_USER=eero.saarinen@helsinki.fi

# Raw reads (inputs, not outputs) stay where samples.tsv points.
BASE=${CW_BASE:-/scratch/project_2019675/the_coffee_wrecks}

# Outputs of every analysis, outside the repo: $OUTPUTS/<analysis>/...
OUTPUTS=/scratch/project_2019675/outputs

REF_DIR=$CW_REPO/data/references/coffea_arabica_ET39
REF=$REF_DIR/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna

SAMPLES_TSV=$CW_REPO/data/samples/samples.tsv
