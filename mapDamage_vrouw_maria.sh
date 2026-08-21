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

module load samtools
module load picard
module load mapdamage2/2.2.2

BASE=/scratch/project_2019675/the_coffee_wrecks
REF=$BASE/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna
SAMPLE=CT600-007R0002
INBAM=$BASE/bwa-out/${SAMPLE}_sorted.bam
DEDUP=$BASE/bwa-out/${SAMPLE}_dedup.bam

mkdir -p $BASE/mapDamage-out

picard MarkDuplicates \
    I=$INBAM \
    O=$DEDUP \
    M=$BASE/mapDamage-out/${SAMPLE}_dup_metrics.txt \
    REMOVE_DUPLICATES=true

samtools index $DEDUP

mapDamage \
    -i $INBAM \
    -r $REF \
    --folder $BASE/mapDamage-out/${SAMPLE}_mapDamage
