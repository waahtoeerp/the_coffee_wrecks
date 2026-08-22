#!/bin/bash
#SBATCH --job-name=gatk-hc
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=08:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

BASE=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load gatk/4.5.0.0
module load samtools/1.21

REF=$BASE/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna
SAMPLE=CT600-007R0002
INBAM=$BASE/bwa-out/${SAMPLE}_rescaled_RG.bam

mkdir -p $BASE/gatk-out

# Variant calling
gatk HaplotypeCaller \
    -R $REF \
    -I $INBAM \
    -O $BASE/gatk-out/${SAMPLE}.g.vcf.gz \
    -ERC GVCF \
    --min-pruning 1 \
    --min-dangling-branch-length 1

