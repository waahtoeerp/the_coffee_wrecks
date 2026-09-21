#!/bin/bash
#SBATCH --job-name=mapdamage-vrouw-maria
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

BASE=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load samtools/1.21
module load picard/3.3.0
module load mapdamage2/2.2.3

REF=$BASE/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna
SAMPLE=$1
INBAM=$BASE/bwa-out/${SAMPLE}_sorted_RG.bam
DEDUP=$BASE/bwa-out/${SAMPLE}_dedup.bam

mkdir -p $BASE/mapDamage-out

# VALIDATION_STRINGENCY=LENIENT: same reason as add_readgroups.sh — bwa
# sampe can emit an unmapped read with a stale nonzero MAPQ, which
# Picard's STRICT default hard-fails on. See that script's comment.
picard MarkDuplicates \
    I=$INBAM \
    O=$DEDUP \
    M=$BASE/mapDamage-out/${SAMPLE}_dup_metrics.txt \
    REMOVE_DUPLICATES=true \
    VALIDATION_STRINGENCY=LENIENT

samtools index $DEDUP

mapDamage \
    -i $INBAM \
    -r $REF \
    --folder $BASE/mapDamage-out/${SAMPLE}_mapDamage

# Cleanup: $INBAM (bwa-out/${SAMPLE}_sorted_RG.bam) is used by both steps
# above (MarkDuplicates and this QC-only mapDamage run) but nothing after
# this script reads it once $DEDUP exists. See bwa-vrouw.sh for why this
# matters (disk-quota crises from parallel sample chains).
rm -f $INBAM $INBAM.bai
