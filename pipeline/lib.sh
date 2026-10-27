#!/bin/bash
# Helpers shared by check.sh, status.sh and RUN_ME.sh. Source after config.sh.

die() {
    echo "FAIL: $*" >&2
    exit 1
}

# Sample IDs from samples.tsv, one per line (skips the header).
sample_ids() {
    awk -F'\t' 'NR > 1 && NF > 0 {print $1}' "$SAMPLES_TSV"
}

# Read paths for one sample: prints "read1 read2" relative to BASE.
sample_reads() {
    awk -F'\t' -v s="$1" 'NR > 1 && $1 == s {print $2, $3}' "$SAMPLES_TSV"
}
