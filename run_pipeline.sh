#!/bin/bash
# Orchestrates the coffee_wrecks pipeline on Roihu by submitting every
# sbatch script with SLURM job dependencies, so each stage only starts
# once the one before it has finished successfully.
#
# setup_reference.sh and vrouw_maria_fastqc_job.sh are sample-independent
# (one-time ref indexing; fastqc already globs all samples' reads in one
# job) so each is submitted once. Everything from bwa-vrouw.sh onward is
# per-sample (SAMPLE passed as $1).
#
# By default each sample is an independent parallel job chain. Pass
# --serial as the first argument to fully serialize instead -- each
# sample's entire chain (bwa through filter) waits for the previous
# sample's last job. Added 2026-09-20 after 3 disk-quota crises from 4
# parallel sample chains each keeping every stage's multi-GB BAM alive
# simultaneously -- serial mode caps peak usage to roughly one sample's
# intermediates instead of 4x. Costs wall-clock time (chains no longer
# overlap at all) in exchange for that safety margin.
#
# Run this from the login node (not itself as an sbatch job):
#   ./run_pipeline.sh                                        # all 4, parallel
#   ./run_pipeline.sh CT600-007R0003 CT600-007R0004           # just these, parallel
#   ./run_pipeline.sh --serial                                # all 4, serial
#   ./run_pipeline.sh --serial CT600-007R0003 CT600-007R0004  # just these, serial

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

SERIAL=0
if [ "${1:-}" = "--serial" ]; then
    SERIAL=1
    shift
fi

if [ "$#" -gt 0 ]; then
    SAMPLES=("$@")
else
    SAMPLES=(CT600-007R0002 CT600-007R0003 CT600-007R0004 CT600-007R0005)
fi

echo "Submitting reference setup and QC (shared across all samples, no dependencies)..."
jid_setup=$(sbatch --parsable setup_reference.sh)
jid_fastqc=$(sbatch --parsable vrouw_maria_fastqc_job.sh)

echo
echo "Shared jobs:"
echo "  setup_reference (ref indexing)       -> $jid_setup"
echo "  fastqc (independent QC, all samples) -> $jid_fastqc"
echo

jid_prev_filter=""
for SAMPLE in "${SAMPLES[@]}"; do
    echo "Submitting chain for $SAMPLE..."
    if [ "$SERIAL" -eq 1 ] && [ -n "$jid_prev_filter" ]; then
        bwa_dep="afterok:$jid_setup:$jid_prev_filter"
    else
        bwa_dep="afterok:$jid_setup"
    fi
    jid_bwa=$(sbatch --parsable --job-name=bwa_$SAMPLE --dependency=$bwa_dep bwa-vrouw.sh "$SAMPLE")
    jid_rg=$(sbatch --parsable --job-name=addrg_$SAMPLE --dependency=afterok:$jid_bwa add_readgroups.sh "$SAMPLE")
    jid_dedup=$(sbatch --parsable --job-name=dedup_$SAMPLE --dependency=afterok:$jid_rg mapDamage_vrouw_maria.sh "$SAMPLE")
    jid_rescale=$(sbatch --parsable --job-name=rescale_$SAMPLE --dependency=afterok:$jid_dedup mapDamage_rescale.sh "$SAMPLE")
    jid_hc=$(sbatch --parsable --job-name=gatkhc_$SAMPLE --dependency=afterok:$jid_rescale:$jid_setup gatk_hc.sh "$SAMPLE")
    jid_geno=$(sbatch --parsable --job-name=genotype_$SAMPLE --dependency=afterok:$jid_hc genotype_gvcf.sh "$SAMPLE")
    # --mail-type=END,FAIL here (overriding each script's own FAIL-only
    # default) sends one email when this sample's chain actually finishes,
    # not just on failure -- this is the last job in the chain, so one
    # email per sample rather than one per stage.
    jid_filter=$(sbatch --parsable --mail-type=END,FAIL --job-name=filter_$SAMPLE --dependency=afterok:$jid_geno gatk-filter.sh "$SAMPLE")
    echo "  $SAMPLE: bwa=$jid_bwa add-rg=$jid_rg dedup=$jid_dedup rescale=$jid_rescale gatk-hc=$jid_hc genotype=$jid_geno filter=$jid_filter"
    jid_prev_filter=$jid_filter
done

cat <<EOF

Visualization not submitted yet — see visualization/ once all 4 samples' base analysis is verified.

Check status with: squeue -u \$USER
EOF
