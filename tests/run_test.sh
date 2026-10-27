#!/bin/bash
# Smoke test: runs the real base pipeline (run_pipeline.sh and every stage script)
# on a tiny synthetic sample, in its own folder, and checks that each stage ran
# and wrote a valid output. It does NOT check that the variant calls are correct.
#
# Uses a 60 kb slice of the real reference and 3000 read pairs. Real outputs,
# real outputs folder and real samples are not touched: every path is overridden
# through CW_* variables (see pipeline/config.sh).
#
# Run from the Roihu login node:
#   tests/run_test.sh              fresh test folder, submit, wait, check
#   tests/run_test.sh --no-submit  generate data and print what would run
#
# Expected runtime: 15-30 minutes, mostly waiting on the queue.

set -uo pipefail

REPO=/scratch/project_2019675/the_coffee_wrecks
TEST=${TEST_ROOT:-/scratch/project_2019675/cw_pipeline_test}
SAMPLE=TEST01
FULL_REF=$REPO/data/references/coffea_arabica_ET39/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna

# Refuse to run anywhere except the test folder we own.
case "$TEST" in
    */cw_pipeline_test) ;;
    *) echo "FAIL: TEST_ROOT must end in cw_pipeline_test (got $TEST)" >&2; exit 1 ;;
esac

fail=0
note() { echo "$*"; }
bad()  { echo "FAIL: $*"; fail=1; }

rm -rf "$TEST"
mkdir -p "$TEST"

export CW_BASE=$TEST
export CW_OUTPUTS=$TEST/outputs
export CW_REF=$TEST/ref/test_ref.fna
export CW_REF_DIR=$TEST/ref
export CW_SAMPLES=$TEST/samples.tsv

python3 "$REPO/tests/make_test_data.py" "$FULL_REF" "$TEST" --sample "$SAMPLE" || { echo "FAIL: test data generation"; exit 1; }

if [ "${1:-}" = "--no-submit" ]; then
    note "Test data written to $TEST. Not submitting."
    exit 0
fi

note "Submitting run_pipeline.sh $SAMPLE ..."
"$REPO/run_pipeline.sh" "$SAMPLE" > "$TEST/submit.log" 2>&1 || { cat "$TEST/submit.log"; echo "FAIL: submission"; exit 1; }
cat "$TEST/submit.log"

IDS=$(grep -oE '[0-9]{6,}' "$TEST/submit.log" | sort -u | paste -sd, -)
[ -n "$IDS" ] || { echo "FAIL: no job ids found in submit log"; exit 1; }

note "Waiting for jobs: $IDS"
while squeue -h -j "$IDS" 2>/dev/null | grep -q .; do sleep 30; done

note ""
note "== job states =="
sacct -j "$IDS" -X --format=JobID,JobName%22,State,ExitCode,Elapsed --noheader | tee "$TEST/sacct.txt"
while read -r jid name state code elapsed; do
    [ "$state" = "COMPLETED" ] && [ "$code" = "0:0" ] || bad "job $jid ($name) state=$state exit=$code"
done < <(sacct -j "$IDS" -X --format=JobID,JobName%22,State,ExitCode --noheader -P | tr '|' ' ')

source "$REPO/load_modules.sh"
module load samtools/1.21 >/dev/null 2>&1

note ""
note "== output checks =="
OUT=$CW_OUTPUTS/base
RESCALED=$OUT/mapDamage-out/${SAMPLE}_mapDamage_dedup/${SAMPLE}_dedup.rescaled.bam
GVCF=$OUT/gatk-out/${SAMPLE}.g.vcf.gz
FILT=$OUT/gatk-out/${SAMPLE}_filtered.vcf.gz

if [ -s "$RESCALED" ] && samtools quickcheck "$RESCALED"; then note "ok   rescaled BAM"; else bad "rescaled BAM missing or corrupt: $RESCALED"; fi
if [ -s "$GVCF" ] && gzip -t "$GVCF"; then note "ok   gVCF"; else bad "gVCF missing or corrupt: $GVCF"; fi
if [ -s "$FILT" ] && gzip -t "$FILT"; then
    note "ok   filtered VCF ($(zcat "$FILT" | grep -vc '^#') records; any count is accepted)"
else
    bad "filtered VCF missing or corrupt: $FILT"
fi

note ""
if [ "$fail" -eq 0 ]; then
    note "PASS: every stage ran and wrote a valid output for $SAMPLE."
else
    note "FAIL: see the lines above. Logs: $REPO/slurm-<JOBID>.out and $REPO/errors_<JOBID>.txt (or slurm-out/)."
fi
exit "$fail"
