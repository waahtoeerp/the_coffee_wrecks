#!/bin/bash
#SBATCH --job-name=gatk-genotype
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=04:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

module load bio-apps/v202603
module load gatk

BASE=/scratch/project_2019675/the_coffee_wrecks
REF=$BASE/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna
SAMPLE=CT600-007R0002

gatk GenotypeGVCFs \
    -R $REF \
    -V $BASE/gatk-out/${SAMPLE}.g.vcf.gz \
    -O $BASE/gatk-out/${SAMPLE}.vcf.gz
