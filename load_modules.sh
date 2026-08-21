#!/bin/bash
# Diagnostic only — not a pipeline stage, not submitted via sbatch.
# Run directly on the login node:
#   bash load_modules.sh
#
# gatk/samtools/bwa/fastqc are currently failing in the real pipeline jobs
# with "requires a toolchain that is incompatible with the currently loaded
# environment" (see PIPELINE.md). `module spider <name>` doesn't load
# anything — it prints the prerequisite module(s)/toolchain you need to load
# first, in order. Paste the full output back so the actual `module load`
# lines in setup_reference.sh, bwa-vrouw.sh, vrouw_maria_fastqc_job.sh etc.
# can be corrected instead of guessed at.

echo "=== module list (default environment at job start) ==="
module list

echo "=== module spider biokit ==="
# Other scripts (vcf_stats.sh, extract_snp_viz_data.sh) load this instead of
# individual tools — checking whether it's the toolchain that unlocks the rest.
module spider biokit

echo "=== module spider gatk ==="
module spider gatk

echo "=== module spider samtools ==="
module spider samtools

echo "=== module spider bwa ==="
module spider bwa

echo "=== module spider fastqc ==="
module spider fastqc

echo "=== module spider picard ==="
# Used by add_readgroups.sh and mapDamage_vrouw_maria.sh — likely to hit the
# same toolchain error once the pipeline gets that far.
module spider picard

echo "=== module spider mapdamage2 ==="
# Used by mapDamage_vrouw_maria.sh / mapDamage_rescale.sh — same reason.
module spider mapdamage2
