#!/bin/bash
# The base analysis: trimming, alignment, read groups, deduplication, damage
# rescaling, variant calling and filtering, for every sample in samples.tsv.
#
# Run from the Roihu login node. It submits the stage jobs itself; do not sbatch it.
#
# Usage:
#   ./run.sh                       check inputs, then submit the chain for all samples
#   ./run.sh --serial              same, one sample at a time
#   ./run.sh CT600-007R0003 ...    submit only these samples
#   ./run.sh status                show the per-sample table, submit nothing
#   ./run.sh --dry-run             check inputs and show what would be submitted

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../pipeline/config.sh"
source "$HERE/../../pipeline/lib.sh"
source "$HERE/config.sh"

case "${1:-}" in
    status)
        exec "$CW_REPO/pipeline/status.sh"
        ;;
    --dry-run)
        "$CW_REPO/pipeline/check.sh" || exit 1
        echo "Would run: $CW_REPO/run_pipeline.sh ${*:2}"
        echo "Samples: $(sample_ids | tr '\n' ' ')"
        exit 0
        ;;
esac

"$CW_REPO/pipeline/check.sh" || exit 1
echo "Run manifest: $(write_manifest "$HERE" "$ANALYSIS" "$@")"

cd "$CW_REPO"
exec ./run_pipeline.sh "$@"
