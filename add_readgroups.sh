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
#
# VALIDATION_STRINGENCY=LENIENT (added 2026-09-21): bwa sampe (the legacy
# aligner used here specifically for aDNA, see PIPELINE.md's "bwa aln
# parameters") can occasionally emit an unmapped read with a stale nonzero
# MAPQ -- technically a SAM spec violation, but not something Picard needs
# to hard-fail on. Picard's STRICT default rejected R0003's whole file
# over exactly one such record (SAM validation error:
# INVALID_MAPPING_QUALITY). This dataset's unusually non-standard pairing
# (~0.003% properly paired, see the signal-funnel finding in PIPELINE.md)
# makes this more likely to surface than in typical modern-DNA data.
picard AddOrReplaceReadGroups \
    I=$INBAM \
    O=$OUTBAM \
    RGID=1 \
    RGLB=lib1 \
    RGPL=ILLUMINA \
    RGPU=unit1 \
    RGSM=$SAMPLE \
    VALIDATION_STRINGENCY=LENIENT

samtools index $OUTBAM

# Cleanup: $INBAM (bwa-out/${SAMPLE}_sorted.bam) is only ever read here —
# nothing downstream needs it once $OUTBAM exists. See bwa-vrouw.sh for
# why this matters (disk-quota crises from 4 parallel sample chains each
# keeping every stage's BAM alive simultaneously).
rm -f $INBAM $INBAM.bai
