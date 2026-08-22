#!/bin/bash
# Orchestrates the coffee_wrecks pipeline on Puhti by submitting every
# sbatch script with SLURM job dependencies, so each stage only starts
# once the one before it has finished successfully.
#
# Run this from the login node (not itself as an sbatch job):
#   ./run_pipeline.sh

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "Submitting reference setup and QC (no dependencies)..."
jid_setup=$(sbatch --parsable setup_reference.sh)
jid_fastqc=$(sbatch --parsable vrouw_maria_fastqc_job.sh)

echo "Submitting alignment..."
jid_bwa=$(sbatch --parsable --dependency=afterok:$jid_setup bwa-vrouw.sh)

echo "Submitting dedup + mapDamage QC..."
jid_dedup=$(sbatch --parsable --dependency=afterok:$jid_bwa mapDamage_vrouw_maria.sh)

echo "Submitting mapDamage rescale..."
jid_rescale=$(sbatch --parsable --dependency=afterok:$jid_dedup mapDamage_rescale.sh)

echo "Submitting read group tagging..."
jid_rg=$(sbatch --parsable --dependency=afterok:$jid_rescale add_readgroups.sh)

echo "Submitting variant calling..."
jid_hc=$(sbatch --parsable --dependency=afterok:$jid_rg:$jid_setup gatk_hc.sh)

echo "Submitting genotyping..."
jid_geno=$(sbatch --parsable --dependency=afterok:$jid_hc genotype_gvcf.sh)

echo "Submitting variant filtering..."
jid_filter=$(sbatch --parsable --dependency=afterok:$jid_geno gatk-filter.sh)

# Visualization (vcf_stats.sh, vcf_plot.sh, extract_snp_viz_data.sh,
# build_snp_viz.py) lives in visualization/ and is not submitted here yet —
# base analysis needs a verified run first. Submit those manually once
# gatk-filter.sh output has been checked.

cat <<EOF

Submitted job chain:
  setup_reference (ref indexing)  -> $jid_setup
  fastqc (independent QC)         -> $jid_fastqc
  bwa-vrouw (align)                -> $jid_bwa
  mapDamage_vrouw_maria (dedup)    -> $jid_dedup
  mapDamage_rescale                -> $jid_rescale
  add_readgroups                   -> $jid_rg
  gatk_hc                          -> $jid_hc
  genotype_gvcf                    -> $jid_geno
  gatk-filter                      -> $jid_filter

Visualization not submitted yet — see visualization/ once the run above is verified.

Check status with: squeue -u \$USER
EOF
