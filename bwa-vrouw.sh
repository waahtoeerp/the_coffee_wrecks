#!/bin/bash
#SBATCH --job-name=bwa_aDNA
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --output=output_%j.txt
#SBATCH --error=errors_%j.txt
#SBATCH --time=12:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

BASE=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load bwa/0.7.19
module load samtools/1.21

REF=$BASE/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna
R1=$BASE/vrouw_maria_2026/Unknown_CT600-007R0002_1.fq.gz
R2=$BASE/vrouw_maria_2026/Unknown_CT600-007R0002_2.fq.gz
SAMPLE=CT600-007R0002
OUTDIR=$BASE/bwa-out

mkdir -p $OUTDIR

# Reference must already be indexed by setup_reference.sh (.bwt/.pac/.ann/.amb/.sa)
# Align
bwa aln -l 16500 -n 0.01 -t 4 $REF $R1 > $OUTDIR/${SAMPLE}_1.sai
bwa aln -l 16500 -n 0.01 -t 4 $REF $R2 > $OUTDIR/${SAMPLE}_2.sai

# Pair and convert
bwa sampe $REF $OUTDIR/${SAMPLE}_1.sai $OUTDIR/${SAMPLE}_2.sai $R1 $R2 | \
    samtools view -bS | \
    samtools sort -o $OUTDIR/${SAMPLE}_sorted.bam

samtools index $OUTDIR/${SAMPLE}_sorted.bam
samtools flagstat $OUTDIR/${SAMPLE}_sorted.bam

