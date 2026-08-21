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

cat <<EOF

Submitted job chain:
  setup_reference (ref indexing)  -> $jid_setup
  fastqc (independent QC)         -> $jid_fastqc


Check status with: squeue -u \$USER
EOF
