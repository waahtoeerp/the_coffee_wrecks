#!/bin/bash
#SBATCH --job-name=blast_smoke
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=04:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

# Smoke test for the taxonomic profiling step: BLASTX of a few test reads
# against the shared NR database on Roihu. Checks that BLAST starts, finds the
# database by name, and writes hits. Not a biological check.
#
# Submit as a job (it does not need to be run from the login node):
#   sbatch tests/blast_smoke.sh
# Or set the number of reads: sbatch --export=ALL,N_READS=50 tests/blast_smoke.sh

set -euo pipefail

REPO=/scratch/project_2019675/the_coffee_wrecks
source $REPO/pipeline/config.sh
module load blast/2.17.0

N_READS=${N_READS:-100}
IN=${CW_TEST_READS:-/scratch/project_2019675/cw_pipeline_test/vrouw_maria_2026_segments/Unknown_TEST01_1.fq.gz}
OUT=$OUTPUTS/blast_test
mkdir -p "$OUT"

zcat "$IN" | awk -v n="$N_READS" 'NR % 4 == 1 && c < n {c++; sub(/^@/, ">"); print; getline; print; getline; getline}' > "$OUT/reads.fa"
echo "reads: $(grep -c '^>' "$OUT/reads.fa")"

start=$(date +%s)
blastx -db nr -query "$OUT/reads.fa" \
    -outfmt "6 qseqid sseqid pident length evalue bitscore staxids sscinames stitle" \
    -max_target_seqs 5 -evalue 1e-5 -num_threads "$SLURM_CPUS_PER_TASK" \
    -out "$OUT/blastx_nr.tsv"
echo "blastx finished in $(( $(date +%s) - start )) s"

hits=$(wc -l < "$OUT/blastx_nr.tsv")
echo "hit lines: $hits"
[ "$hits" -gt 0 ] || { echo "FAIL: no hits written"; exit 1; }
echo "PASS: BLAST ran against the shared NR database and wrote $hits hit lines."
