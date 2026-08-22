#!/bin/bash
# Shared module setup for the coffee_wrecks pipeline on Roihu.
# Source this from every sbatch script, after BASE is defined:
#   source $BASE/load_modules.sh
#   module load samtools/1.21 gatk/4.5.0.0   # etc, whatever that script needs
#
# Root cause of the "requires a toolchain that is incompatible with the
# currently loaded environment" errors seen for gatk/samtools/bwa/fastqc/
# picard (see slurm-out/slurm-778195.out, slurm-778196.out): Roihu's login
# and job shells auto-load a default StdEnv toolchain (gcc/15.2.0, openmpi,
# ucx, openblas). bio-apps/v202603 ships its own, incompatible toolchain —
# `module load bio-apps/v202603` on top of StdEnv succeeds silently, but
# every tool inside bio-apps then fails to resolve until StdEnv is
# unloaded first.
#
# Confirmed via `module spider <name>` on 2026-08-22:
#   samtools  -> bio-apps/v202603, exact version samtools/1.21
#   gatk      -> bio-apps/v202603, exact version gatk/4.5.0.0
#   bwa       -> bio-apps/v202603, exact version bwa/0.7.19
#   fastqc    -> bio-apps/v202603, exact version fastqc/0.12.1
#   picard    -> bio-apps/v202603, exact version picard/3.3.0
#   bcftools  -> bio-apps/v202603, exact version bcftools/1.23.1
#   mapdamage2 -> standalone, no bio-apps prerequisite: mapdamage2/2.2.3
#                 (mapDamage_rescale.sh / mapDamage_vrouw_maria.sh currently
#                 request mapdamage2/2.2.2, which does not exist — update to
#                 2.2.3)
#
# Bare names (e.g. `module load samtools`) are avoided here on purpose:
# pin exact versions so a future bio-apps release can't silently change
# what a script runs against.

module purge
module load bio-apps/v202603