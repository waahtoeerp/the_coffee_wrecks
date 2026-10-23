# Restructure plan (proposal, not yet applied)

Status: planning only. No existing files have been moved. Moving them changes the paths that Roihu jobs use, so that happens in a separate step, after the Roihu deployment in [deploy-roihu.md](deploy-roihu.md) is verified.

## Handoff (read this first)

Last updated 2026-10-23.

**Blocker.** Do not run anything on Roihu for this work until the security issue on Roihu is closed and CSC has confirmed the cluster is usable for this project. [deploy-roihu.md](deploy-roihu.md) has the checklist. Until then, only local edits, docs and `.gitignore` changes are safe.

**Where things stand**

- The verified baseline is the git tag `baseline-2026-09-21` (commit `140c62b`): all four samples through the pipeline, filtered variant counts R0002=233, R0003=209, R0004=208, R0005=63.
- Base pipeline changes since the baseline are on `dev`. Latest relevant commits:
  - `c9313d6`: `bwa-vrouw.sh` always rebuilds `.sai` files instead of reusing them (stale-file risk removed; a resubmission after a timeout now repeats `bwa aln`).
  - `94c0198`: `PIPELINE.md` updated to match.
  - `3f1a68e`: `.gitignore` exceptions for `samples.tsv`, reference manifests and run manifests; outputs and logs ignored.
- Kraken2 screening (repo `CW_metagenomic_screening`, `main`): the positive control passed on both databases. The parents-only database (no ET-39 reference) is the meaningful test; it classifies 100% of the mapped reads as *Coffea*. Summary: `visualization/viz-data/positive_control_kraken2.json`.
- A synthetic end-to-end run (FAKE01) completed every stage. It was a plumbing test only; the synthetic data has no planted variants, so the result (0 PASS) says nothing about calling accuracy. It is not needed further.

**Uncommitted in `the_coffee_wrecks` (decide before committing)**

- The `CW_BASE` override (`BASE=${CW_BASE:-...}`) in 12 scripts. Harmless default, but it is only useful for the fake-data test, which is no longer needed. Either commit it or revert it.
- `tests/make_fake_reads.py`: the fake-data generator. Keep it only if the plumbing test is wanted again.
- Untracked `output_*.txt`, `errors_*.txt` and `slurm-*` files at the repo root. These are job logs and should not be committed.

**Known issues to fix in the restructure**

- `build_coffee_kraken2_db.sh` and `build_parents_kraken2_db.sh` need a taxonomy folder that `kraken2-build --clean` deletes. The taxonomy should be kept in a stable place (for example `data/` or a `pipeline/` cache) and copied from there.
- `PIPELINE.md` and `README.md` both describe the old `.sai` behaviour in places; the 2026-10-23 entry supersedes them, but the rows should be tidied when the docs are next edited.
- The mapDamage version was wrong in an earlier script (`2.2.2`); both scripts now load `2.2.3`. Check on the first run after deployment.

**Next steps, in order**

1. Wait for the Roihu security issue to be closed and confirmed by CSC.
2. Settle the uncommitted items above.
3. Write `pipeline/config.sh`, `pipeline/check.sh`, `pipeline/status.sh` and `data/samples/samples.tsv` next to the current scripts, without moving anything.
4. Port the base chain into `analyses/base/` and `pipeline/stages/`. Check it reproduces the baseline counts on all four samples.
5. Add the first new analysis on top of the base outputs.

**Decisions already made**

- Samples and references are shared; outputs are never copied between analyses.
- Done-markers are written only after output checks pass; an exit code alone is never enough.
- `RUN_ME.sh` submits each analysis's stages as one SLURM chain with `afterok`.
- Run manifests are tracked in `analyses/<name>/manifests/`.
- The screening repo stays separate and reads base outputs by path, pending the open question below.
- Roihu runs are started by a person from a terminal, not by an AI tool.

**Open questions**

- Which analysis comes next? Its needs decide the shared-stage interface.
- Keep `CW_metagenomic_screening` separate, or make it an analysis?
- Move `poster/` and `claude-backup/` out of the repo root, or leave them?
- The Roihu steps in `visualization/`: move them into analyses once stable, or keep them where they are?

## Goal

Several analyses run on the same samples and the same reference, and each one is reproducible, runnable by hand, and fails loudly. No AI is needed in the execution path.

## Concepts

- **Samples and references are shared.** They are defined once and referenced by name.
- **The base** is the alignment chain every analysis starts from: trimming, `bwa`, read groups, deduplication, damage rescaling. It runs once per sample. Its outputs are the verified baseline (`baseline-2026-09-21`).
- **An analysis** is a folder that takes the base outputs as input and produces its own results. Examples: variant calling, a different filter, a new damage model, a comparison.
- **Outputs are never copied.** An analysis that needs base output names it by path in its config.

## Target layout

```
the_coffee_wrecks/
  README.md                    start here: what exists, and the one command per analysis
  data/
    samples/samples.tsv        sample ID, read paths, sequencing info (shared by all analyses)
    references/
      coffea_arabica_ET39/
        manifest.env           source URL, checksum, output names, tool versions
        fetch.sh               download, verify, index; writes a built marker
  pipeline/
    config.sh                  account, base path, mail address, OUTPUTS root: defined once
    lib.sh                     die(), done-marker helpers, output-check helpers
    check.sh                   checks samples, reference, modules, and upstream markers
    status.sh                  one table: analyses by samples by stages
    stages/                    shared stage scripts, each parameterised by its config
      bwa.sh
      add_readgroups.sh
      dedup.sh
      rescale.sh
      gatk_hc.sh
      genotype_gvcf.sh
      gatk_filter.sh
  analyses/
    base/
      RUN_ME.sh                runs the shared chain for every sample
      config.sh                samples, reference, parameters
      notes.md                 decisions and why
    variant_call/
      RUN_ME.sh
      config.sh                input: base outputs; parameters for this analysis
      notes.md
      stages/                  stage scripts that only this analysis uses
  visualization/               unchanged for now
  docs/
```

Outputs live outside the repo, under `OUTPUTS` from `pipeline/config.sh`, one folder per analysis:

```
$OUTPUTS/base/<SAMPLE>/...
$OUTPUTS/variant_call/<SAMPLE>/...
```

Each analysis folder has a gitignored `output/` symlink to its place under `$OUTPUTS` and a gitignored `log/` folder.

## How a run works

`RUN_ME.sh` in each analysis does three things:

1. Reads its `config.sh`, then `pipeline/config.sh`.
2. Runs `pipeline/check.sh`. This checks the samples, the reference, the modules, and every upstream input. If an upstream analysis has not finished, the check names it, for example "run base first".
3. Submits its stages as one SLURM dependency chain with `afterok`, the same mechanism `run_pipeline.sh` uses now.

Usage, the same for every analysis:

```
./RUN_ME.sh              submit whatever is not done yet
./RUN_ME.sh status       show the table, submit nothing
./RUN_ME.sh --dry-run    show the commands that would be submitted
```

`pipeline/status.sh` prints one table covering all analyses, so you can see what is done, failed or waiting at a glance.

## Done-markers and output checks

- A stage writes its done-marker only after its output checks pass. Exit code alone is never enough. Example: `bwa` writes its marker only after `samtools quickcheck` passes on the BAM.
- Markers are per analysis, per sample, per stage, under that analysis's `output/`.
- Each analysis's `notes.md` lists the output check for each of its stages.

## Shared code versus analysis code

- **Shared stages** in `pipeline/stages/` are used by more than one analysis. They take all their parameters from the calling analysis's config, so one script serves every analysis.
- **Analysis-specific stages** live in that analysis's `stages/` folder.
- A change to a shared stage affects every analysis that uses it. Each run records the git commit it ran from, so any result can be reproduced.
- Before changing a shared stage for a new analysis, check that the base still reproduces the verified results (baseline VCF counts: R0002=233, R0003=209, R0004=208, R0005=63).

## Run manifest

Each analysis writes a manifest into `analyses/<name>/manifests/` at the start of a run: the git commit, the config contents, the sample list and the date. The manifests are small and tracked in git, so they live in the repo rather than under `$OUTPUTS`. This makes every result traceable to the code and settings that produced it.

## Migration order

1. Build `pipeline/` and `data/samples/` alongside the current scripts, without moving anything.
2. Port the base chain into `analyses/base/` and `pipeline/stages/`, and check that it reproduces the baseline counts on the four samples.
3. Add the first new analysis (`variant_call` or the next one) on top of the base outputs.
4. Move `visualization/` Roihu steps into the analyses once they are stable.

Steps 1–2 run only after the Roihu deployment is verified.

## Rules

- A stage must not succeed without writing its done-marker, and must not write it unless its output checks pass.
- Data is never copied between analyses. An analysis that needs another's output names it by path.
- `data/` and `pipeline/` hold small text files and shared helpers only. Large files are gitignored.
- Logs and outputs never go into git.

## Open questions

- Which analysis comes next? Its needs decide the exact shared-stage interface, so the first port should be done with it in mind.
- The screening repo, `CW_metagenomic_screening`: keep it separate and read base outputs by path, or fold it in as an analysis? It is a second repo, so that is a decision for you.
- `poster/` and `claude-backup/` are not part of the pipeline. Move them out of the root, or leave them?
