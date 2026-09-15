#!/bin/bash
# Run directly on the Roihu login node — not an sbatch job (same reasoning
# as extract_snp_viz_data.sh/vcf_stats.sh: lightweight, only ever feeds a
# local-machine plotting step).
#
# Computes the read-attrition funnel (raw -> mapped -> unique-after-dedup)
# entirely from mapDamage-out/${SAMPLE}_dup_metrics.txt, which already
# contains every number needed (see 2026-09-03 finding in PIPELINE.md) —
# no dependency on bwa-vrouw.sh's old flagstat job logs, which aren't
# guaranteed to still exist.
#
# Usage: ./extract_signal_funnel.sh <SAMPLE>
#   e.g. ./extract_signal_funnel.sh CT600-007R0002

set -euo pipefail

BASE=/scratch/project_2019675/the_coffee_wrecks
SAMPLE=$1
DUPMETRICS=$BASE/mapDamage-out/${SAMPLE}_dup_metrics.txt
OUTDIR=$BASE/visualization/viz-data
OUT=$OUTDIR/${SAMPLE}_signal_funnel.json

mkdir -p $OUTDIR

python3 - "$SAMPLE" "$DUPMETRICS" "$OUT" << 'PYEOF'
import sys, json

sample, dupmetrics_path, out_path = sys.argv[1:4]

with open(dupmetrics_path) as f:
    lines = f.read().splitlines()
hdr_i = next(i for i, l in enumerate(lines) if l.startswith("LIBRARY"))
cols = lines[hdr_i].split("\t")
vals = lines[hdr_i + 1].split("\t")
d = dict(zip(cols, vals))

unpaired_examined = int(d["UNPAIRED_READS_EXAMINED"])
pairs_examined = int(d["READ_PAIRS_EXAMINED"])
unmapped = int(d["UNMAPPED_READS"])
unpaired_dup = int(d["UNPAIRED_READ_DUPLICATES"])
pair_dup = int(d["READ_PAIR_DUPLICATES"])
est_library_size = int(d["ESTIMATED_LIBRARY_SIZE"]) if d["ESTIMATED_LIBRARY_SIZE"] else None

mapped = unpaired_examined + pairs_examined * 2
raw = mapped + unmapped
dup_reads = unpaired_dup + pair_dup * 2
unique = mapped - dup_reads

out = {
    "sample": sample,
    "raw_reads": raw,
    "mapped_reads": mapped,
    "mapped_pct_of_raw": mapped / raw,
    "duplicate_reads": dup_reads,
    "duplicate_pct_of_mapped": dup_reads / mapped,
    "unique_reads": unique,
    "unique_pct_of_raw": unique / raw,
    "estimated_library_size": est_library_size,
}
with open(out_path, "w") as f:
    json.dump(out, f, indent=2)
print(f"Wrote {out_path}")
print(json.dumps(out, indent=2))
PYEOF
