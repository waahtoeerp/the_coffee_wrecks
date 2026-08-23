---
name: project-coffee-wrecks-pipeline
description: Status and history of the ancient-DNA pipeline in /scratch/project_2019675/the_coffee_wrecks on CSC Roihu
metadata: 
  node_type: memory
  type: project
  originSessionId: 3c865b03-f9a7-4ddc-a113-27cfcd07d56a
  modified: 2026-08-23T07:12:23.026Z
---

Project: `/scratch/project_2019675/the_coffee_wrecks` on CSC's Roihu HPC cluster (SLURM account `project_2019675`), a git repo (branch `dev`). An ancient-DNA (aDNA) pipeline — bwa/GATK/mapDamage — analyzing degraded coffee-bean DNA samples (naming suggests the "Vrouw Maria" shipwreck) against the *Coffea arabica* reference genome `GCF_036785885.1` (RefSeq, cultivar ET-39).

**User's history/continuity note (2026-08-23):** the user's chat/session history has been deleted before, so don't assume conversation continuity — treat this memory, the repo's git log, and `PIPELINE.md`'s own "Recently fixed" changelog as the durable record. Re-read `PIPELINE.md` at the start of any new session touching this project; it's kept current and is more authoritative than this memory for pipeline mechanics.

## Session arc (2026-08-22 → 2026-08-23), most recent state first

1. **Multi-sample generalization (2026-08-23):** all per-sample scripts (`bwa-vrouw.sh`, `add_readgroups.sh`, `mapDamage_vrouw_maria.sh`, `mapDamage_rescale.sh`, `gatk_hc.sh`, `genotype_gvcf.sh`, `gatk-filter.sh`) now take `SAMPLE` as `$1`. `run_pipeline.sh` submits `setup_reference.sh`/`vrouw_maria_fastqc_job.sh` once (sample-independent) then loops per-sample parallel job chains; accepts optional sample names on the CLI (`./run_pipeline.sh CT600-007R0003 ...`) to target a subset instead of redoing already-completed samples. The 4 samples are `CT600-007R0002` (fully verified complete — real 230-record filtered VCF) through `R0005`. Jobs 790806–790829 were submitted for R0003/R0004/R0005 and were running as of this writing — check `sacct` for current state before assuming anything.
2. **Hardening (2026-08-23):** added `set -euo pipefail` to all 13 job scripts. Root cause: none of them had it, so SLURM reported "COMPLETED" even when a command inside failed partway (happened twice — a masked `MarkDuplicates` NullPointerException, and a masked `CreateSequenceDictionary` PicardException). `setup_reference.sh` made idempotent (skip-if-exists per step) since it's resubmitted on every `run_pipeline.sh` call.
3. **Real correctness bug fixed:** Picard `MarkDuplicates` requires `@RG`-tagged input; `add_readgroups.sh` used to run *after* dedup instead of before it. Reordered: `bwa-vrouw.sh` → `add_readgroups.sh` → `mapDamage_vrouw_maria.sh` → `mapDamage_rescale.sh` → `gatk_hc.sh`.
4. **Data provisioning fixed:** the reference `.fna` was completely missing — fetched from NCBI RefSeq directly via `curl` (no `datasets` CLI module on Roihu), MD5-verified. Separately, all 8 raw read files under `vrouw_maria_2026_segments/` were actually *directories* — leftovers of an incomplete OpenStack Swift/Allas large-object transfer from the user's other CSC project (which they plan to shut down once this one is stable). Reconstructed via ordered `cat` of the numbered segments, `gzip -t`-verified before deleting the segment directories.
5. **Module-loading root cause fixed:** Roihu's login/job shells auto-load a default `StdEnv` toolchain (gcc/openmpi/ucx/openblas) incompatible with the `bio-apps/v202603` tree that holds samtools/gatk/bwa/fastqc/picard/bcftools/mapdamage2. Fix is `module purge` before `module load bio-apps/v202603`, centralized in a sourced `load_modules.sh` used by every script, with exact pinned tool versions (not bare names).
6. **`visualization/` reorg:** `vcf_stats.sh`, `vcf_plot.sh`, `extract_snp_viz_data.sh`, `build_snp_viz.py`, `viz-data/`, `vcf-stats-out/` moved into their own `visualization/` folder, deliberately *not* wired into `run_pipeline.sh` yet — visualization is deferred until the base analysis is verified for all 4 samples.

## Pending / next steps
- Once R0003–R0005 finish, verify each the same way R0002 was (check real output files/record counts, not just `sacct` state).
- Generalize `visualization/` scripts (`vcf_stats.sh`, `vcf_plot.sh`, `extract_snp_viz_data.sh`) to take `SAMPLE` as `$1` too, same pattern as the base pipeline.
- **Dashboard design decision (agreed, not yet built):** user wants "every sample deserves own sheet/page." Recommendation given and accepted in spirit: one HTML dashboard with a per-sample sidebar/tab nav, reusing `build_snp_viz.py`'s existing chart-rendering JS and embedding each sample's JSON, rather than 4 disconnected HTML files. `build_snp_viz.py`'s `find_sample()` currently only handles one sample per invocation (picks the first `*_snps.tsv` found, warns and ignores the rest) — this needs rewriting for multi-sample.
- A prior commit (`5b4fd91`, 2026-08-22, made by the user themselves) captured the module-fix + viz-folder-move state. Everything since (RG-order fix, `set -e` hardening, multi-sample parameterization) was uncommitted as of 2026-08-23 when the user asked for a "backup" of the conversation — recommended committing to git as the actually-durable backup mechanism (survives chat history loss, unlike anything conversation-based).

## Environment notes
- SLURM `--mail-user` on every job script is `eero.saarinen@helsinki.fi` (work email) — distinct from the harness's `userEmail` context field.
- Some old comments/scripts still say "Puhti" (the cluster's predecessor) instead of "Roihu" — harmless but a sign of copy-pasted history; worth cleaning up opportunistically, not urgent.
- Stray `output_<jobid>.txt`/`errors_<jobid>.txt` files accumulate in the repo root from `bwa-vrouw.sh`'s `#SBATCH --output`/`--error` directives — untracked, not gitignored, low-priority cleanup.
