#!/bin/bash
#SBATCH --job-name=ref-setup
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G

module load gatk
module load samtools

BASE=/scratch/project_2019675
REF=$BASE/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna

# One-time reference indexing, needed by gatk_hc.sh.
# Run once per reference; safe to skip on reruns if .fai/.dict already exist.
samtools faidx $REF
gatk CreateSequenceDictionary -R $REF
