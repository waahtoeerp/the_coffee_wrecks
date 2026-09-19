#!/bin/bash
#SBATCH --job-name=bwa_aDNA
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --output=output_%j.txt
#SBATCH --error=errors_%j.txt
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

BASE=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load fastp/1.0.1
module load bwa/0.7.19
module load samtools/1.21

REF=$BASE/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna
SAMPLE=$1
R1=$BASE/vrouw_maria_2026_segments/Unknown_${SAMPLE}_1.fq.gz
R2=$BASE/vrouw_maria_2026_segments/Unknown_${SAMPLE}_2.fq.gz
OUTDIR=$BASE/bwa-out
TRIM_R1=$OUTDIR/${SAMPLE}_trimmed_1.fq.gz
TRIM_R2=$OUTDIR/${SAMPLE}_trimmed_2.fq.gz

mkdir -p $OUTDIR

# Adapter/quality trimming. Added 2026-09 after CW_metagenomic_screening
# found genuine 3' adapter read-through on reads shorter than the 150bp
# read length (see that repo's LABDIARY.md) — short aDNA fragments read
# past the end of the real insert and into adapter sequence, which
# obviously can't align. Doesn't recover meaningfully more mapped reads
# (confirmed in that investigation — what was found was mostly on
# already-uninformative low-complexity repeat sequence), but is the right
# thing to do for data quality on what does map.
fastp -i $R1 -I $R2 -o $TRIM_R1 -O $TRIM_R2 \
    --json $OUTDIR/${SAMPLE}_fastp.json --html $OUTDIR/${SAMPLE}_fastp.html \
    --thread 4

# Reference must already be indexed by setup_reference.sh (.bwt/.pac/.ann/.amb/.sa)
# Align. bwa aln is the slow part (hours) and was what timed out under
# concurrent-sample cluster contention on 2026-08-23 — skip it on resubmission
# if the .sai already exists. This is a plain existence check, not a
# completeness check: if a run was killed *during* bwa aln itself (rather
# than after, like the 2026-08-23 case), delete the partial .sai and rerun.
# NOTE: this now also means a stale .sai from before this fastp step was
# added must be deleted manually before resubmitting, since it was built
# from untrimmed reads and this check can't tell the difference.
[ -f "$OUTDIR/${SAMPLE}_1.sai" ] || bwa aln -l 16500 -n 0.01 -t 4 $REF $TRIM_R1 > $OUTDIR/${SAMPLE}_1.sai
[ -f "$OUTDIR/${SAMPLE}_2.sai" ] || bwa aln -l 16500 -n 0.01 -t 4 $REF $TRIM_R2 > $OUTDIR/${SAMPLE}_2.sai

# Pair and convert
bwa sampe $REF $OUTDIR/${SAMPLE}_1.sai $OUTDIR/${SAMPLE}_2.sai $TRIM_R1 $TRIM_R2 | \
    samtools view -bS | \
    samtools sort -o $OUTDIR/${SAMPLE}_sorted.bam

samtools index $OUTDIR/${SAMPLE}_sorted.bam
samtools flagstat $OUTDIR/${SAMPLE}_sorted.bam

# Cleanup: once sorted.bam exists (the line above didn't fail under set -e),
# the trimmed fastq is no longer needed by anything and is cheap to
# regenerate (fastp is fast, unlike bwa aln) — deleting it here is what
# keeps 4 parallel sample chains from repeating the 2026-09-03/09-19 disk-
# quota crises now that there's an extra ~14GB/sample of trimmed-fastq
# intermediates in the mix. .sai is deliberately kept (see above — it's
# the expensive step to redo). NOTE: this means a full rerun of an already-
# completed sample needs its .sai deleted too, not just resubmission —
# bwa sampe below needs $TRIM_R1/$TRIM_R2, which won't exist otherwise.
rm -f $TRIM_R1 $TRIM_R2

