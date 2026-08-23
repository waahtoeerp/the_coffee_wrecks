#!/bin/bash
#SBATCH --job-name=vcf-plot
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=00:15:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

module load python-data/3.12-31.03

BASE=/scratch/project_2019675/the_coffee_wrecks
cd $BASE/visualization/vcf-stats-out/CT600-007R0002_plots/
python plot.py
