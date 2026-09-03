#!/bin/bash
# Run directly on the Roihu login node — not an sbatch job. Produces
# visualization/vcf-stats-out/${SAMPLE}_stats.txt and ${SAMPLE}_plots/plot.py,
# both small enough to copy to a local machine. plot.py itself is generated
# by plot-vcfstats but only ever *run* locally (see vcf_plot.sh).
#
# Usage: ./vcf_stats.sh <SAMPLE>
#   e.g. ./vcf_stats.sh CT600-007R0002

set -euo pipefail

BASE=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load bcftools/1.23.1

SAMPLE=$1
OUTDIR=$BASE/visualization/vcf-stats-out

mkdir -p $OUTDIR/${SAMPLE}_plots

bcftools stats \
    $BASE/gatk-out/${SAMPLE}_filtered.vcf.gz \
    > $OUTDIR/${SAMPLE}_stats.txt

# -P: skip the PDF-summary step. plot-vcfstats otherwise shells out to
# pdflatex/tectonic, neither of which exists on Roihu, and dies — even
# though plot.py and the individual .png/.dat files (everything vcf_plot.sh
# and build_snp_viz.py actually need) are already written by that point.
plot-vcfstats \
    -P \
    -p $OUTDIR/${SAMPLE}_plots/ \
    $OUTDIR/${SAMPLE}_stats.txt
