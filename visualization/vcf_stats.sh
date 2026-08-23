#!/bin/bash
#SBATCH --job-name=vcf-stats
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

BASE=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load bcftools/1.23.1

SAMPLE=CT600-007R0002
OUTDIR=$BASE/visualization/vcf-stats-out

mkdir -p $OUTDIR/${SAMPLE}_plots

bcftools stats \
    $BASE/gatk-out/${SAMPLE}_filtered.vcf.gz \
    > $OUTDIR/${SAMPLE}_stats.txt

plot-vcfstats \
    -p $OUTDIR/${SAMPLE}_plots/ \
    $OUTDIR/${SAMPLE}_stats.txt
