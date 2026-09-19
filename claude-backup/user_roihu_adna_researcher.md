---
name: user-roihu-adna-researcher
description: "User's HPC/bioinformatics context — CSC Roihu cluster, ancient-DNA pipelines"
metadata: 
  node_type: memory
  type: user
  originSessionId: 3c865b03-f9a7-4ddc-a113-27cfcd07d56a
  modified: 2026-08-23T07:12:48.854Z
---

Works with ancient-DNA (aDNA) bioinformatics pipelines on CSC's Roihu supercomputer (Finland), specifically project `project_2019675` (see [[project-coffee-wrecks-pipeline]]). Comfortable with SLURM, bash, and standard bioinformatics tools (bwa, GATK, samtools, Picard, mapDamage, bcftools) — but was initially unfamiliar with Roihu-specific Lmod/module-system quirks ("i do not understand how to load modules at roihu"), so explain module/toolchain issues concretely (what `module spider` actually shows) rather than assuming prior Roihu experience.

Has (at least) two CSC projects; pulls large sequencing data between them via Allas (CSC's Swift-based object storage) and plans to shut down the source project once the current one is running smoothly — so data-provisioning issues traced back to Allas transfers are plausible and worth checking for.

Email: work address `eero.saarinen@helsinki.fi` is used as the SLURM `--mail-user` in job scripts.
