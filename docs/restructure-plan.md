# Restructure plan (proposal, not yet applied)

Status: planning only. No existing files have been moved. Moving them changes the paths that Roihu jobs use, so that happens in a separate step after the Roihu deployment in [deploy-roihu.md](deploy-roihu.md) is verified.

## Idea

Each analysis is a self-contained project: its own stage scripts, its own settings, its own notes, and its own logs. Shared things live in one place only when they really are shared: the reference libraries, the sample list, and the small helper code.

Two kinds of thing are shared differently:

- **Code is copied into a project** when the project needs it. A project stays readable and runnable on its own, and git history shows which version each project used.
- **Data is never copied.** A project that needs another project's output points to it by path. The output exists once.

A person should be able to open the repo, read the root `README.md`, and run one command per project.

## Target layout

```
the_coffee_wrecks/
  README.md                  start here: the projects, and the one command for each
  data/
    samples/
      samples.tsv            the vrouw_maria samples: ID, read paths on scratch, sequencing info
    references/
      _template/             copy this to add a reference
      coffea_arabica_ET39/
        manifest.env         source URL, checksum, output filename, tool versions
        fetch.sh             download, verify, index; writes built.txt
  pipeline/                  shared helpers only; projects source these, they do not copy them
    config.sh                account, base path, mail address, outputs root: defined once
    lib.sh                   die(), done-marker helpers, input checks
    check.sh                 checks inputs and modules before anything is submitted
    status.sh                one table: samples by stages
  projects/
    _template/               copy this to start a project
      RUN_ME.sh              the one command for this project
      config.sh              samples, reference, stage list, inputs (paths to other projects' outputs if needed)
      notes.md               the question, the decisions, and why
    variant_call/
      RUN_ME.sh
      config.sh
      notes.md               lab diary
      bwa.sh                 this project's own copy of each stage it runs
      gatk_hc.sh
      genotype_gvcf.sh
      gatk-filter.sh
      output/                symlink to $OUTPUTS/variant_call (gitignored)
      log/                   Slurm logs, named by stage and sample (gitignored)
  docs/
    restructure-plan.md      this file
    deploy-roihu.md          steps to deploy once Roihu is usable again
    PIPELINE.md, ...         existing reference docs
  visualization/             unchanged for now; the local part belongs to CW_viz_pipeline
```

Outputs are not stored inside the repo tree. `pipeline/config.sh` defines one outputs root on scratch, for example `OUTPUTS=/scratch/project_2019675/outputs`. Each project writes to `$OUTPUTS/<project>/`. The `output/` folder in the project is a symlink to that place, so a person browsing the project still sees its results there. Outputs are gitignored, as they are today.

## RUN_ME.sh

Each project has one `RUN_ME.sh`. It does three things and nothing else:

1. Reads its own `config.sh`, and the shared settings from `pipeline/config.sh`.
2. Runs `pipeline/check.sh`. This checks the samples, the reference, the modules, and any input from another project. If a check fails, it stops and says why, including which project to run first.
3. Runs each stage in order, using the project's own scripts. A stage with a done-marker is skipped.

Usage:

```
./RUN_ME.sh           run everything that is not done yet
./RUN_ME.sh status    show the table, submit nothing
./RUN_ME.sh --dry-run show the commands that would be submitted
```

Nothing is submitted unless the person runs `./RUN_ME.sh` without a flag.

## Sharing between projects

**Code.** Each project keeps its own copy of every stage script it runs. Changing a copy affects only that project. If another project should get the change, copy it deliberately and note the copy in both projects' `notes.md`. Once three projects carry the same stage, move the shared version into `pipeline/stages/` and have the projects call it from there.

**Data.** Never copy outputs between projects. If project B needs project A's output, B's `config.sh` names it by path, for example `INPUT_BAM=$OUTPUTS/variant_call/bwa/sample_rg.bam`. `check.sh` confirms the file exists and that its done-marker is present before B runs. If it is missing, B stops and names project A as the one to run first.

**References and samples.** Shared by name through `data/`. A project never contains a path to a reference, only its folder name.

## Rules that make this work

- `data/` holds manifests and small text files only. Large files are fetched or built by a script and gitignored.
- A new reference is added by copying `data/references/_template/`, not by editing an existing one.
- Logs and outputs never go into git.

## Open questions before applying

- `poster/` and `claude-backup/` are not part of the pipeline. Move them out of the root, or leave them?
- `visualization/` mixes Roihu extraction steps with local plotting. Should the Roihu steps move into their project folder and the local steps stay in `visualization/`?
- `.gitignore` ignores `data/*`. The `samples.tsv` and reference manifests will need explicit `!` exceptions when they are added. It will also need `projects/*/output/` and `projects/*/log/`.
- Shell or Python for the shared helpers. The stage scripts stay in bash, since they run on the cluster. Python would suit `status.sh` and the doc generation, but this depends on which Python Roihu has, so it is deferred.
- Deferred: a `projects/` index file listing each project and its question. Not needed yet; the folder names and each `notes.md` are enough. Revisit when there are more than four or five projects.
