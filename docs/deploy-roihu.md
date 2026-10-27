# Deploying the restructured pipeline on Roihu

Status: ready to use. Roihu is open again and the login node is confirmed working.

The steps assume the restructure in [restructure-plan.md](restructure-plan.md) has been applied and committed. They are written so that each step can be checked before the next one runs.

## Before you start

- [x] Roihu login node is working (confirmed 2026-10-23).
- [ ] You know which login node and account you will use. The account is in `pipeline/config.sh`. Do not guess it.
- [ ] You have checked the current CSC rules on automated tools and connections, as noted in the pipeline guide.
- [ ] You have checked which area of scratch is purged and how often. Reference libraries may need to live in project storage instead.
- [ ] The run is done by you, from a terminal on Roihu. Do not give an AI tool access to the cluster until you have decided that separately.

## 1. Get the code

On the Roihu login node, in the project's scratch area:

```
cd /scratch/project_2019675/the_coffee_wrecks
git status
git log --oneline -3
git pull origin dev
```

Check that `git status` shows no local changes. If it does, stop and find out what they are before pulling. Do not discard them without knowing why they are there.

Record the commit you are running, so you can return to it:

```
git rev-parse --short HEAD
```

## 2. Check the reference libraries

For each reference that a project uses:

```
cd data/references/<name>
cat manifest.env
cat built.txt
md5sum <output file>
```

The checksum from `md5sum` must match `expected_md5` in `manifest.env`. If the file is missing or the checksum differs, rebuild it with `./fetch.sh`. Do not use a file whose checksum you have not compared.

## 3. Check the samples

```
cat data/samples/samples.tsv
```

Confirm that every read path in the file exists on scratch. The `check.sh` step below does this automatically, but read the file yourself once.

## 4. Run the check

```
cd analyses/<analysis-name>
./run.sh --dry-run
```

Read the output. It lists the commands that would be submitted, and any check that failed. Do not continue while any check shows FAIL.

## 5. Submit one sample first

Before running every sample, run one:

```
./run.sh CT600-007R0003
```

Wait for it to finish, then check it:

```
./run.sh status
```

For any failed stage, the status table shows the log path. Read the last lines of that log before doing anything else.

## 6. Run the rest

Once one sample completes and its outputs look right:

```
./run.sh
```

## Recovery

- **A stage failed:** read its log, fix the cause, then rerun with `./run.sh`. Stages with a done-marker are skipped, so only the failed stage and the ones after it run again.
- **A stage needs to run again even though it is done:** delete its done-marker, not the output. The marker is in `<output folder>/.done/`.
- **The code is broken after a pull:** go back to the commit you recorded in step 1 with `git checkout <commit>`. Do not reset or delete files on scratch to fix this.
- **A reference was purged:** rebuild it with `./fetch.sh`, then repeat step 2.

## After the first successful run

- Record the commit, the project name, and the run date in that project's `notes.md`.
- Note any step that needed a manual fix, and why. These notes are how the pipeline gets easier to run without help.
