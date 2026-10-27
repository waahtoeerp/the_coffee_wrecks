#!/bin/bash
# Download, verify and decompress the reference into the reference folder (this directory). Run on the Roihu
# login node (needs HTTPS to NCBI). Refuses to overwrite a file that fails its
# checksum. Indexing is done by setup_reference.sh, not here.
#
# Usage: data/references/coffea_arabica_ET39/fetch.sh [--force]

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/manifest.env"
source "$HERE/../../../pipeline/config.sh"

OUT="$REF_DIR/$OUTPUT_FILE"
GZ="$REF_DIR/${ASSEMBLY}_genomic.fna.gz"
FORCE=${1:-}

mkdir -p "$REF_DIR"

if [ -s "$OUT" ] && [ "$FORCE" != "--force" ]; then
    got=$(md5sum "$OUT" | cut -d' ' -f1)
    if [ "$got" = "$EXPECTED_MD5_FNA" ]; then
        echo "OK: $OUT already present and matches manifest."
        exit 0
    fi
    echo "FAIL: $OUT exists but md5 is $got (expected $EXPECTED_MD5_FNA). Not overwriting. Use --force to replace it." >&2
    exit 1
fi

if [ ! -s "$GZ" ] || [ "$(md5sum "$GZ" | cut -d' ' -f1)" != "$EXPECTED_MD5_GZ" ]; then
    curl -fsS -o "$GZ" "$SOURCE_DIR/${ASSEMBLY}_genomic.fna.gz"
fi

got_gz=$(md5sum "$GZ" | cut -d' ' -f1)
if [ "$got_gz" != "$EXPECTED_MD5_GZ" ]; then
    rm -f "$GZ"
    echo "FAIL: downloaded file md5 is $got_gz, expected $EXPECTED_MD5_GZ. Removed it; try again." >&2
    exit 1
fi

gunzip -c "$GZ" > "$OUT.partial"
got_fna=$(md5sum "$OUT.partial" | cut -d' ' -f1)
if [ "$got_fna" != "$EXPECTED_MD5_FNA" ]; then
    rm -f "$OUT.partial"
    echo "FAIL: decompressed md5 is $got_fna, expected $EXPECTED_MD5_FNA." >&2
    exit 1
fi
mv "$OUT.partial" "$OUT"
echo "OK: $OUT downloaded, verified and decompressed. Next: setup_reference.sh (indexes)."
