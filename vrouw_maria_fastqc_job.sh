#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

module load bio-apps/v202603
module load fastqc

BASE=/scratch/project_2019675/the_coffee_wrecks
OUTDIR=$BASE/fastqc-out

mkdir -p $OUTDIR

fastqc -t 4 -o $OUTDIR $BASE/vrouw_maria_2026_segments/*.fq.gz
