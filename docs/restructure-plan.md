# Restructure plan (proposal, not yet applied)

Status: planning only. No existing files have been moved. Moving them changes the paths that Roihu jobs use, so that happens in a separate step, after the Roihu deployment in [deploy-roihu.md](deploy-roihu.md) is verified.

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
