#!/bin/bash
#SBATCH --job-name=mapdamage-dedup
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
module load mapdamage2/2.2.3

REF=$BASE/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna
SAMPLE=$1
DEDUP=$BASE/bwa-out/${SAMPLE}_dedup.bam

mkdir -p $BASE/mapDamage-out

samtools index $DEDUP

mapDamage \
    -i $DEDUP \
    -r $REF \
    --rescale \
    --folder $BASE/mapDamage-out/${SAMPLE}_mapDamage_dedup

# Indexed here since this rescaled BAM (already RG-tagged, carried through
# from add_readgroups.sh via MarkDuplicates) now feeds gatk_hc.sh directly.
RESCALED=$BASE/mapDamage-out/${SAMPLE}_mapDamage_dedup/${SAMPLE}_dedup.rescaled.bam
samtools index $RESCALED

# Cleanup: $DEDUP is only ever read here — gatk_hc.sh and everything after
# it reads $RESCALED instead. See bwa-vrouw.sh for why this matters
# (disk-quota crises from parallel sample chains).
rm -f $DEDUP $DEDUP.bai

