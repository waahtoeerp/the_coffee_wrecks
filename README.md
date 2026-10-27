# Coffee Wrecks aDNA pipeline (Roihu)

Runs on CSC Roihu from `/scratch/project_2019675/the_coffee_wrecks`. Each step is a SLURM job; you start the pipeline from the login node and check it yourself.

## Where things are

- `analyses/base/` — the alignment chain every analysis starts from. `./analyses/base/RUN_ME.sh status` shows the per-sample table; `./analyses/base/RUN_ME.sh --dry-run` checks inputs without submitting. Its notes and verified baseline are in `analyses/base/notes.md`.
- `analyses/metagenomic_screening/` — Kraken2 screening of the off-target reads. Its scripts still use the data in `CW_metagenomic_screening`'s original directory; see its `notes.md`.
- `pipeline/` — shared settings (`config.sh`), the input check (`check.sh`), and the status table (`status.sh`).
- `data/` — the sample list (`samples/samples.tsv`) and the reference manifest (`references/coffea_arabica_ET39/`).
- `docs/restructure-plan.md` — the layout plan and its current status. `docs/deploy-roihu.md` — checklist for running on Roihu.

The step-by-step instructions below predate this layout and still describe the same scripts.

## Before you start

- Raw reads must be at `vrouw_maria_2026_segments/Unknown_<SAMPLE>_1.fq.gz` and `_2.fq.gz`. If they come as segments, concatenate and check each file with `gzip -t` first.
- The reference `ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna` must be present. `setup_reference.sh` builds its indexes.
- Work on the `dev` branch, and note the verified baseline tag `baseline-2026-09-21`.

## Run the pipeline

```bash
cd /scratch/project_2019675/the_coffee_wrecks
./run_pipeline.sh                                  # all 4 samples, in parallel
./run_pipeline.sh CT600-007R0003 CT600-007R0004    # only these samples
./run_pipeline.sh --serial                         # one sample at a time (use this if disk space is tight)
```

This submits every stage as a SLURM job with dependencies: reference setup, FastQC, `bwa-vrouw.sh`, `add_readgroups.sh`, `mapDamage_vrouw_maria.sh`, `mapDamage_rescale.sh`, `gatk_hc.sh`, `genotype_gvcf.sh`, `gatk-filter.sh`.

## Check the run

```bash
squeue -u $USER                                    # what is still running or pending
sacct -u $USER -S today --format=JobID,JobName%22,State,ExitCode,Elapsed -X
```

A job marked `COMPLETED` is not enough on its own. For each sample, check the output:

```bash
zcat gatk-out/<SAMPLE>_filtered.vcf.gz | grep -vc '^#'        # records written
zcat gatk-out/<SAMPLE>_filtered.vcf.gz | grep -v '^#' | awk -F'\t' '{print $7}' | sort | uniq -c
```

If a job failed, its log is `slurm-<JOBID>.out` in this directory (the `bwa-vrouw.sh` logs are `output_<JOBID>.txt` and `errors_<JOBID>.txt`). Jobs that depend on a failed job are cancelled automatically.

## Reruns

- `bwa-vrouw.sh` always re-runs `fastp` and `bwa aln`, and deletes any existing `.sai` first. Rerunning a sample costs the full `bwa aln` time (hours), but a stale `.sai` can't be reused by accident.
- Trimmed reads are deleted after each run, so a rerun regenerates them automatically; no manual cleanup is needed.

## Visualization (login node, after a sample is verified)

```bash
./visualization/extract_signal_funnel.sh <SAMPLE>
./visualization/extract_snp_viz_data.sh <SAMPLE>
./visualization/vcf_stats.sh <SAMPLE>
```

Results go to `visualization/viz-data/` and `visualization/vcf-stats-out/`. Plots are made locally from those files.

## Details

`PIPELINE.md` covers every stage, the parameters and their literature basis, the QC funnel, and the change history.

---

# Muista

tagilla löydät commitin johon palata jos meni mönkään.

```bash
git tag
## claude-toihin

git log --oneline --decorate
##7f22122 (HEAD -> dev, tag: claude-toihin, origin/dev) update

````
