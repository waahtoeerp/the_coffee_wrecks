#!/bin/bash
#SBATCH --job-name=gatk-genotype
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=04:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

BASE=${CW_BASE:-/scratch/project_2019675/the_coffee_wrecks}
source $BASE/pipeline/config.sh
source $BASE/load_modules.sh
module load gatk/4.5.0.0

SAMPLE=$1

gatk GenotypeGVCFs \
    -R $REF \
    -V $OUTPUTS/base/gatk-out/${SAMPLE}.g.vcf.gz \
    -O $OUTPUTS/base/gatk-out/${SAMPLE}.vcf.gz
