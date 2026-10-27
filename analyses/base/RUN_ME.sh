#!/bin/bash
# The base analysis: trimming, alignment, read groups, deduplication, damage
# rescaling, variant calling and filtering, for every sample in samples.tsv.
#
# Usage:
#   ./RUN_ME.sh                       check inputs, then submit the chain
#   ./RUN_ME.sh --serial              same, one sample at a time
#   ./RUN_ME.sh CT600-007R0003 ...    submit only these samples
#   ./RUN_ME.sh status                show the table, submit nothing
#   ./RUN_ME.sh --dry-run             check inputs and show what would be submitted
#
# Submission is done by run_pipeline.sh, the same script used before this
# layout existed. Its stage order and dependencies are not changed here.

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

MANIFEST_DIR="$HERE/manifests"
MANIFEST="$MANIFEST_DIR/$(date +%Y%m%d-%H%M%S).manifest"
mkdir -p "$MANIFEST_DIR"
{
    echo "analysis: $ANALYSIS"
    echo "date: $(date -Iseconds)"
    echo "commit: $(git -C "$CW_REPO" rev-parse --short HEAD)"
    echo "dirty_files: $(git -C "$CW_REPO" status --short | grep -v '^??' | wc -l)"
    echo "args: $*"
    echo "samples:"
    sample_ids | sed 's/^/  /'
    echo "--- pipeline/config.sh ---"
    cat "$CW_REPO/pipeline/config.sh"
    echo "--- analyses/base/config.sh ---"
    cat "$HERE/config.sh"
} > "$MANIFEST"
echo "Run manifest: $MANIFEST"

cd "$CW_REPO"
exec ./run_pipeline.sh "$@"
