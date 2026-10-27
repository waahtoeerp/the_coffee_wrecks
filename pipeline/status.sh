#!/bin/bash
# One table for the base analysis: per sample, whether its final outputs exist
# and how many records the filtered VCF has. Intermediates are deleted as the
# chain runs, so the final outputs are what is checked here.
#
# Usage: pipeline/status.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/config.sh"
source "$HERE/lib.sh"

yn() { [ -s "$1" ] && echo "yes" || echo "no"; }

printf '%-16s %-10s %-10s %-14s %s\n' SAMPLE RESCALED gVCF FILTERED RECORDS
while read -r s; do
    rescaled="$BASE/mapDamage-out/${s}_mapDamage_dedup/${s}_dedup.rescaled.bam"
    gvcf="$BASE/gatk-out/${s}.g.vcf.gz"
    filt="$BASE/gatk-out/${s}_filtered.vcf.gz"
    records="-"
    if [ -s "$filt" ]; then
        records=$(zcat "$filt" | grep -vc '^#')
    fi
    printf '%-16s %-10s %-10s %-14s %s\n' "$s" "$(yn "$rescaled")" "$(yn "$gvcf")" "$(yn "$filt")" "$records"
done < <(sample_ids)
