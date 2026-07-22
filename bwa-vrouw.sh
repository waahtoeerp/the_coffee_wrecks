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

module load bwa
module load samtools

REF=/scratch/project_2019675/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna
R1=/scratch/project_2019675/vrouw_maria_2026/Unknown_CT600-007R0002_1.fq.gz
R2=/scratch/project_2019675/vrouw_maria_2026/Unknown_CT600-007R0002_2.fq.gz
SAMPLE=CT600-007R0002

# Index (skip if already done)
bwa index $REF

# Align
bwa aln -l 16500 -n 0.01 -t 4 $REF $R1 > ${SAMPLE}_1.sai
bwa aln -l 16500 -n 0.01 -t 4 $REF $R2 > ${SAMPLE}_2.sai

# Pair and convert
bwa sampe $REF ${SAMPLE}_1.sai ${SAMPLE}_2.sai $R1 $R2 | \
    samtools view -bS | \
    samtools sort -o ${SAMPLE}_sorted.bam

samtools index ${SAMPLE}_sorted.bam
samtools flagstat ${SAMPLE}_sorted.bam

