# Pipeline run order

| # | Script | Reads | Writes | Notes |
|---|--------|-------|--------|-------|
| 1 | `vrouw_maria_fastqc_job.sh` | `vrouw_maria_2026/*.fq.gz` | FastQC report, **next to the raw fastq files** (no `-o` flag given) | QC-only, independent branch — nothing downstream consumes it. Consider adding `-o` to a dedicated `fastqc-out/` dir instead of writing reports into the raw data folder. |
| 2 | `bwa-vrouw.sh` | `ref_gen/*.fna`, `vrouw_maria_2026/*_1.fq.gz`/`_2.fq.gz` | `${SAMPLE}_sorted.bam` + `.sai` files | ⚠️ Output has no path prefix at all — it writes to whatever directory you happen to `sbatch` this from, not to `bwa-out/`. No `mkdir -p bwa-out` and no `$BASE/bwa-out/` prefix on any output. Every downstream script assumes `bwa-out/${SAMPLE}_sorted.bam` exists — this script needs fixing to actually put it there. |
| 3 | `mapDamage_vrouw_maria.sh` | `bwa-out/${SAMPLE}_sorted.bam` | *(should write)* `bwa-out/${SAMPLE}_dedup.bam` | ⚠️ Broken — `MarkDuplicates` block commented out, so dedup BAM is never produced. |
| 4 | `mapDamage_rescale.sh` | `bwa-out/${SAMPLE}_dedup.bam` | `mapDamage-out/${SAMPLE}_mapDamage_dedup/${SAMPLE}_dedup.rescaled.bam` | Blocked until step 3 is fixed. |
| 5 | `add_readgroups.sh` | `mapDamage-out/.../..._dedup.rescaled.bam` | `bwa-out/${SAMPLE}_rescaled_RG.bam` | No `mkdir -p bwa-out` (relies on step 2 creating it, which it currently doesn't). |
| 6 | `gatk_hc.sh` | `bwa-out/${SAMPLE}_rescaled_RG.bam` | `gatk-out/${SAMPLE}.g.vcf.gz` | Has `mkdir -p gatk-out`. Ref indexing (`faidx`/`CreateSequenceDictionary`) should move to a one-time setup step. |
| 7 | `genotype_gvcf.sh` | `gatk-out/${SAMPLE}.g.vcf.gz` | `gatk-out/${SAMPLE}.vcf.gz` | Fine. |
| 8 | `gatk-filter.sh` | `gatk-out/${SAMPLE}.vcf.gz` | `gatk-out/${SAMPLE}_filtered.vcf.gz` | Fine. |
| 9 | `vcf_stats.sh` **or** `vcf-stats.sh` | `gatk-out/${SAMPLE}_filtered.vcf.gz` | `vcf-stats-out/${SAMPLE}_stats.txt`, `.../plots/` | ⚠️ Duplicate pair — pick one, delete the other. |
| 10 | `vcf_plot.sh` | `vcf-stats-out/${SAMPLE}_plots/plot.py` | rendered plots | Must run after step 9. |
