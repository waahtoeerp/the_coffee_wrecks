#!/bin/bash
# Checks inputs before anything is submitted. Exits non-zero, listing every
# problem, so nothing is queued on bad input. Reads files only; it does not
# decompress or verify read contents (too slow on multi-GB files).
#
# Usage: pipeline/check.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/config.sh"
source "$HERE/lib.sh"

problems=0
problem() { echo "FAIL: $*" >&2; problems=$((problems + 1)); }

[ -f "$SAMPLES_TSV" ] || problem "samples file missing: $SAMPLES_TSV"

if [ -f "$SAMPLES_TSV" ]; then
    header=$(head -1 "$SAMPLES_TSV")
    [ "$header" = "$(printf 'sample_id\tread1\tread2')" ] || problem "samples.tsv header must be: sample_id<TAB>read1<TAB>read2"

    n=0
    while read -r sample; do
        n=$((n + 1))
        read -r r1 r2 <<< "$(sample_reads "$sample")"
        for r in "$r1" "$r2"; do
            if [ ! -s "$BASE/$r" ]; then
                problem "$sample: read file missing or empty: $BASE/$r"
            fi
        done
    done < <(sample_ids)
    [ "$n" -gt 0 ] || problem "samples.tsv lists no samples"
fi

for f in "$REF" "$REF.fai" "${REF%.fna}.dict" "$REF.bwt"; do
    [ -s "$f" ] || problem "reference file missing: $f (run setup_reference.sh)"
done

for tool in sbatch squeue sacct; do
    command -v "$tool" >/dev/null 2>&1 || problem "$tool not on PATH (is this the Roihu login node?)"
done

if [ "$problems" -gt 0 ]; then
    echo "check.sh: $problems problem(s). Nothing was submitted." >&2
    exit 1
fi
echo "check.sh: inputs OK ($(sample_ids | wc -l) samples, reference present)"
