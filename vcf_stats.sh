#!/bin/bash
#SBATCH --job-name=vcf-stats
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G

module load biokit

BASE=/scratch/project_2019675/the_coffee_wrecks
SAMPLE=CT600-007R0002

mkdir -p $BASE/vcf-stats-out/${SAMPLE}_plots

bcftools stats \
    $BASE/gatk-out/${SAMPLE}_filtered.vcf.gz \
    > $BASE/vcf-stats-out/${SAMPLE}_stats.txt

plot-vcfstats \
    -p $BASE/vcf-stats-out/${SAMPLE}_plots/ \
    $BASE/vcf-stats-out/${SAMPLE}_stats.txt
