#!/bin/bash
#SBATCH --job-name=add-rg
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

BASE=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load picard/3.3.0
module load samtools/1.21

SAMPLE=$1
INBAM=$BASE/bwa-out/${SAMPLE}_sorted.bam
OUTBAM=$BASE/bwa-out/${SAMPLE}_sorted_RG.bam

mkdir -p $BASE/bwa-out

# Runs right after bwa-vrouw.sh, before mapDamage_vrouw_maria.sh's
# MarkDuplicates step — Picard's MarkDuplicates requires @RG-tagged input
# and throws a NullPointerException without it (bwa aln/sampe never adds RG).
picard AddOrReplaceReadGroups \
    I=$INBAM \
    O=$OUTBAM \
    RGID=1 \
    RGLB=lib1 \
    RGPL=ILLUMINA \
    RGPU=unit1 \
    RGSM=$SAMPLE

samtools index $OUTBAM
