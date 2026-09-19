---
name: feedback-confirm-costly-actions
description: "Flag scope/cost before big HPC compute jobs or irreplaceable-data operations, then move fast once confirmed"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3c865b03-f9a7-4ddc-a113-27cfcd07d56a
  modified: 2026-08-23T07:12:41.159Z
---

Before kicking off something with real compute cost (multi-hour SLURM job chains) or touching irreplaceable data (reconstructing sequencing reads, deleting segment files, large file moves in a git repo), explain what's about to happen and its cost/risk, and get a quick confirmation first — but once confirmed, execute the whole well-scoped follow-through without re-asking per step.

**Why:** in [[project-coffee-wrecks-pipeline]] work, the user consistently wanted a heads-up before things like reconstructing ~58GB of segmented FASTQ data, resubmitting a 6-hour `bwa` alignment, or generalizing 13 scripts at once — but answered quickly ("yes", "fetch it", "do reconstruction") once the plan and cost were clear, and never wanted to be re-asked for each mechanical sub-step of an already-approved plan (e.g. adding `set -e` to 13 files after one "yes, add it").

**How to apply:** surface the cost/risk and a concrete plan (what will run, how long, what gets touched) as a short heads-up or an `AskUserQuestion` when there's a real design fork; once they answer, carry the whole approved unit of work through without pausing again for equivalent-risk sub-steps within it.
