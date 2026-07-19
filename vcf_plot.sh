#!/bin/bash
#SBATCH --job-name=vcf-plot
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=00:15:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G

module load python-data

cd /scratch/project_2019675/vcf-stats-out/CT600-007R0002_plots/
python plot.py
