#!/bin/bash
# The metagenomic screening analysis: Kraken2 classification of the off-target
# reads, per sample, against the PlusPF-8 database (contamination profile) and
# the coffee database (direct coffee-match check). Prerequisites, built once:
# download_kraken2_db.sh, download_coffee_taxonomy.sh, build_coffee_kraken2_db.sh.
#
# Run from the Roihu login node. It submits the jobs itself; do not sbatch it.
#
# Usage:
#   ./run.sh                       check prerequisites, then submit for all samples
#   ./run.sh CT600-007R0003 ...    submit only these samples
#   ./run.sh status                show what exists per sample, submit nothing
#   ./run.sh --dry-run             check prerequisites and show what would be submitted

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../pipeline/config.sh"
source "$HERE/../../pipeline/lib.sh"
source "$HERE/config.sh"

SCREEN_OUT=$OUTPUTS/$ANALYSIS
problems=0
need() { [ -s "$1" ] || { echo "FAIL: missing $2: $1" >&2; problems=$((problems + 1)); }; }
need "$SCREEN_OUT/kraken2_db/hash.k2d" "PlusPF-8 database (run download_kraken2_db.sh)"
need "$SCREEN_OUT/coffee_kraken2_db/hash.k2d" "coffee database (run build_coffee_kraken2_db.sh)"
[ "$problems" -eq 0 ] || { echo "Prerequisites missing. Nothing was submitted." >&2; exit 1; }

if [ "${1:-}" = "status" ]; then
    printf '%-16s %-10s %-12s %-14s\n' SAMPLE SUBSAMPLE KRAKEN2_ALL KRAKEN2_COFFEE
    while read -r s; do
        yn() { [ -s "$1" ] && echo yes || echo no; }
        printf '%-16s %-10s %-12s %-14s\n' "$s" \
            "$(yn "$SCREEN_OUT/results/$s/${s}_subsample.fq.gz")" \
            "$(yn "$SCREEN_OUT/results/$s/${s}_kraken2_report.txt")" \
            "$(yn "$SCREEN_OUT/results/$s/${s}_kraken2_coffee_report.txt")"
    done < <(sample_ids)
    exit 0
fi

if [ "${1:-}" = "--dry-run" ]; then
    echo "Prerequisites OK."
    echo "Would run: $HERE/run_screening.sh ${*:2}"
    echo "Samples: $(sample_ids | tr '\n' ' ')"
    exit 0
fi

echo "Run manifest: $(write_manifest "$HERE" "$ANALYSIS" "$@")"
exec "$HERE/run_screening.sh" "$@"
