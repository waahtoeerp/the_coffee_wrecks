# Restructure plan (proposal, not yet applied)

Status: planning only. No existing files have been moved. Moving them changes the paths that Roihu jobs use, so that happens in a separate step, after the Roihu deployment in [deploy-roihu.md](deploy-roihu.md) is verified.

## Goal

A person can run the pipeline by hand, see what state it is in, and trust that a failed stage stops the run and says why. No AI is needed in the execution path.

## What we are doing now

Keep the project small. The pipeline has one analysis, one reference and four samples, so this plan adds only what solves current problems:

1. **`samples.tsv`**: one file listing sample IDs and read paths. Replaces sample names hardcoded in about 13 scripts.
2. **`pipeline/check.sh`**: checks inputs, modules and the reference before anything is submitted. A failed check stops the run and says why.
3. **`pipeline/status.sh`**: one table, samples by stages, showing done, failed, or not started.
4. **Done-markers, written only after the stage's output checks pass.** A stage never writes its marker on exit code alone. For example, `bwa` writes its marker only after `samtools quickcheck` passes on the BAM. This is what stops the `COMPLETED`-but-wrong problem from coming back.
5. **`RUN_ME.sh`** in the project root. It runs `check.sh`, then submits every stage as one SLURM dependency chain with `afterok`, the same mechanism `run_pipeline.sh` uses now. The chain keeps the cluster busy and means a failed stage cancels the rest. `RUN_ME.sh status` and `RUN_ME.sh --dry-run` show the state and the commands without submitting anything.
6. **Outputs outside the repo.** `pipeline/config.sh` sets one outputs root on scratch. Logs and outputs are gitignored.

## Deferred until a second project exists

- `data/references/` with manifests and a template. One reference is enough for now.
- `projects/_template/`. Copy one project's layout when a second project actually exists.
- `pipeline/stages/` shared stage scripts, and the projects index file.
- A `visualization/` restructure. It stays as it is.

## The screening repo

`CW_metagenomic_screening` stays a separate repo for now. It consumes the coffee outputs by path, through its own config, and does not get copied into this tree. Its own `README.md` documents its run steps. Folding it in is a decision for later, once the core above works.

## Rules

- A stage script must not succeed without writing its done-marker, and must not write its marker unless its output checks pass.
- Data is never copied between projects. A project that needs another's output names it by path.
- `data/` and `pipeline/` hold small text files and shared helpers only. Large files are gitignored.
- Logs and outputs never go into git.

## Open questions before applying

- What exactly counts as a passing output check for each stage? Write the list before applying, one line per stage.
- `poster/` and `claude-backup/` are not part of the pipeline. Move them out of the root, or leave them?
- `visualization/` mixes Roihu extraction steps with local plotting. Do the Roihu steps move into the pipeline, and the local steps stay in `visualization/`?
- `.gitignore` needs explicit exceptions for `samples.tsv` and the status files, and must ignore the outputs and logs folders.
