#!/bin/bash
#SBATCH --job-name=ref-setup
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=03:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

module load gatk
module load samtools
module load bwa

BASE=/scratch/project_2019675/the_coffee_wrecks
REF=$BASE/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna

# One-time reference indexing, needed by bwa-vrouw.sh and gatk_hc.sh.
# Run once per reference; safe to skip on reruns if .fai/.dict/.bwt etc already exist.
samtools faidx $REF
gatk CreateSequenceDictionary -R $REF
bwa index $REF
