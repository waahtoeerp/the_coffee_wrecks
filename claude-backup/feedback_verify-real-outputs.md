---
name: feedback-verify-real-outputs
description: "Always verify actual output files/content on HPC pipelines, not SLURM state or exit codes"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3c865b03-f9a7-4ddc-a113-27cfcd07d56a
  modified: 2026-08-23T07:12:31.275Z
---

On SLURM/HPC pipeline work, always check the actual output artifacts (file exists, has sane size/content, record counts look right) before declaring a stage successful — never trust `sacct`/`squeue` state or a script's exit code alone.

**Why:** in [[project-coffee-wrecks-pipeline]], this exact gap caused two real, silent failures to go unnoticed: SLURM reported "COMPLETED" for a job where Picard's `MarkDuplicates` had thrown a `NullPointerException` partway through, and separately for one where `CreateSequenceDictionary` threw a `PicardException` — in both cases the script had no `set -e`, so it kept running later commands and exited 0 even though a critical step failed. The user was explicitly glad this was caught by reading the actual log content and checking that expected output files existed, not by trusting the "COMPLETED" status.

**How to apply:** after any SLURM job (or shell script generally) reports success, grep its log for error/exception patterns and independently confirm the expected output file(s) exist with plausible size/content — e.g. actually open a VCF and count records, not just check `.vcf.gz` exists. This matters most right after adding a fix, before telling the user something now works.
