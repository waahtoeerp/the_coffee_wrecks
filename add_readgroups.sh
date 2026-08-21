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

module load picard
module load samtools

BASE=/scratch/project_2019675/the_coffee_wrecks
SAMPLE=CT600-007R0002
INBAM=$BASE/mapDamage-out/${SAMPLE}_mapDamage_dedup/${SAMPLE}_dedup.rescaled.bam
OUTBAM=$BASE/bwa-out/${SAMPLE}_rescaled_RG.bam

mkdir -p $BASE/bwa-out

picard AddOrReplaceReadGroups \
    I=$INBAM \
    O=$OUTBAM \
    RGID=1 \
    RGLB=lib1 \
    RGPL=ILLUMINA \
    RGPU=unit1 \
    RGSM=$SAMPLE

samtools index $OUTBAM
