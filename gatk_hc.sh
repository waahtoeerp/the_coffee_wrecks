#!/bin/bash
#SBATCH --job-name=gatk-hc
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=08:00:00
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
module load samtools/1.21

SAMPLE=$1
INBAM=$OUTPUTS/base/mapDamage-out/${SAMPLE}_mapDamage_dedup/${SAMPLE}_dedup.rescaled.bam

mkdir -p $OUTPUTS/base/gatk-out

# Variant calling
gatk HaplotypeCaller \
    -R $REF \
    -I $INBAM \
    -O $OUTPUTS/base/gatk-out/${SAMPLE}.g.vcf.gz \
    -ERC GVCF \
    --min-pruning 1 \
    --min-dangling-branch-length 1

