#!/bin/bash
#SBATCH --job-name=gatk-filter
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

module load gatk

BASE=/scratch/project_2019675/the_coffee_wrecks
REF=$BASE/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna
SAMPLE=CT600-007R0002

gatk VariantFiltration \
    -R $REF \
    -V $BASE/gatk-out/${SAMPLE}.vcf.gz \
    -O $BASE/gatk-out/${SAMPLE}_filtered.vcf.gz \
    --filter-expression "QD < 2.0" --filter-name "LowQD" \
    --filter-expression "FS > 60.0" --filter-name "HighFS" \
    --filter-expression "MQ < 40.0" --filter-name "LowMQ" \
    --filter-expression "DP < 3" --filter-name "LowDP"
