#!/bin/bash
# Helpers shared by check.sh, status.sh and run.sh. Source after config.sh.

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

# Writes a run manifest into <analysis dir>/manifests/ and prints its path.
# Records what was run, from which commit, with which settings.
# Usage: write_manifest <analysis dir> <analysis name> [args...]
write_manifest() {
    local dir=$1 name=$2
    shift 2
    local mdir="$dir/manifests"
    local f="$mdir/$(date +%Y%m%d-%H%M%S).manifest"
    mkdir -p "$mdir"
    {
        echo "analysis: $name"
        echo "date: $(date -Iseconds)"
        echo "commit: $(git -C "$CW_REPO" rev-parse --short HEAD)"
        echo "dirty_files: $(git -C "$CW_REPO" status --short | grep -v '^??' | wc -l)"
        echo "args: $*"
        echo "samples:"
        sample_ids | sed 's/^/  /'
        echo "--- pipeline/config.sh ---"
        cat "$CW_REPO/pipeline/config.sh"
        echo "--- $dir/config.sh ---"
        [ -f "$dir/config.sh" ] && cat "$dir/config.sh"
    } > "$f"
    echo "$f"
}
