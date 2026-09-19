#!/bin/bash
# Run directly on the Roihu login node — not an sbatch job. The BAM/VCF it
# reads only exist on Roihu; this produces small .tsv/.txt extracts in
# visualization/viz-data/ that get copied to a local machine for plotting
# (vcf_plot.sh / build_snp_viz.py — those run entirely locally, not here).
#
# Usage: ./extract_snp_viz_data.sh <SAMPLE>
#   e.g. ./extract_snp_viz_data.sh CT600-007R0002

set -euo pipefail

BASE=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load bcftools/1.23.1
module load samtools/1.21

SAMPLE=$1
VCF=$BASE/gatk-out/${SAMPLE}_filtered.vcf.gz
BAM=$BASE/mapDamage-out/${SAMPLE}_mapDamage_dedup/${SAMPLE}_dedup.rescaled.bam
OUTDIR=$BASE/visualization/viz-data
WINDOW=2000
BINSIZE=25

mkdir -p $OUTDIR

# 1. SNP table (SNPs only, no indels): chrom, pos, ref, alt, qual, filter, depth, genotype
bcftools view -v snps $VCF | \
    bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\t%FILTER\t[%DP]\t[%GT]\n' \
    > $OUTDIR/${SAMPLE}_snps.tsv

# 2. Per-contig coverage overview (one line per contig/chromosome in the whole genome)
samtools coverage $BAM > $OUTDIR/${SAMPLE}_coverage_by_contig.txt

# 3. Local depth curve around each SNP (+/- WINDOW bp), binned to keep the file small
echo -e "chrom\tsnp_pos\tbin_start\tmean_depth" > $OUTDIR/${SAMPLE}_snp_local_depth.tsv

while IFS=$'\t' read -r CHROM POS REF ALT QUAL FILTER DP GT; do
    START=$(( POS - WINDOW > 0 ? POS - WINDOW : 1 ))
    END=$(( POS + WINDOW ))
    samtools depth -a -r ${CHROM}:${START}-${END} $BAM | \
        awk -v chrom="$CHROM" -v pos="$POS" -v bin="$BINSIZE" '
            {
                b = int(($2-1)/bin)*bin + 1
                sum[b]+=$3; cnt[b]++
            }
            END {
                for (k in sum) printf "%s\t%d\t%d\t%.2f\n", chrom, pos, k, sum[k]/cnt[k]
            }' | sort -k3,3n
done < $OUTDIR/${SAMPLE}_snps.tsv >> $OUTDIR/${SAMPLE}_snp_local_depth.tsv

echo "Done. Small output files written to $OUTDIR:"
ls -la $OUTDIR/${SAMPLE}_snps.tsv $OUTDIR/${SAMPLE}_coverage_by_contig.txt $OUTDIR/${SAMPLE}_snp_local_depth.tsv
