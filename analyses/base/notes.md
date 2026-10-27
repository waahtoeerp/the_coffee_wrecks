# Base analysis: notes

The alignment chain every other analysis starts from. Runs once per sample.

## Verified baseline

Tag `baseline-2026-09-21` (commit `140c62b`). All four samples through the full chain. Filtered variant records:

| Sample | Filtered records |
|---|---|
| CT600-007R0002 | 233 |
| CT600-007R0003 | 209 |
| CT600-007R0004 | 208 |
| CT600-007R0005 | 63 |

Any change to a shared stage must reproduce these counts before it is accepted.

## Stages

1. `fastp` adapter and quality trimming (`bwa-vrouw.sh`). Adapter read-through on short aDNA fragments. Damage is not removed.
2. `bwa aln -l 16500 -n 0.01` then `bwa sampe` (`bwa-vrouw.sh`). Backtrack algorithm, chosen for short damaged reads. `.sai` files are always rebuilt (commit `c9313d6`).
3. Read groups, `AddOrReplaceReadGroups`, `VALIDATION_STRINGENCY=LENIENT` (`add_readgroups.sh`).
4. `MarkDuplicates`, `VALIDATION_STRINGENCY=LENIENT`, and the pre-rescale mapDamage QC (`mapDamage_vrouw_maria.sh`).
5. `mapDamage --rescale` (`mapDamage_rescale.sh`).
6. GATK HaplotypeCaller, GenotypeGVCFs, VariantFiltration (`gatk_hc.sh`, `genotype_gvcf.sh`, `gatk-filter.sh`).

## Running

- `./run.sh` checks inputs and submits the chain through `run_pipeline.sh`.
- `./run.sh status` shows the per-sample table.
- Stage order and dependencies are those of `run_pipeline.sh`; nothing is moved yet.

## Known gaps (to fix after the reproduction run)

- `run_pipeline.sh` still lists the four sample names itself. It should read `data/samples/samples.tsv`.
- Stages write no done-markers yet; `status.sh` checks final output files instead.
- `BASE` comes from `CW_BASE` and defaults to `/scratch/project_2019675/the_coffee_wrecks`. Outputs have not moved to `$OUTPUTS`.
