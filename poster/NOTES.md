# Poster notes — SDCC (Science of Coffee) poster draft material

Working notes to draft from, not poster text itself. Figures in `figures/`.

## Headline result: authentic ancient-DNA damage signature

`figures/damage_curves_all_samples.png` (`.pdf` also available, vector). Built from `mapDamage-out/*_mapDamage_dedup/{5pCtoT,3pGtoA}_freq.txt` (post-dedup — deduplicated first so PCR copies of one damaged molecule can't inflate the apparent signal) via `poster/make_damage_plot.py`.

All 4 samples show the classic aDNA deamination signature: elevated 5′ C→T substitution frequency at the read terminus, decaying to baseline within ~8–10bp.

| Sample | Position-1 C→T | Baseline (pos 11–15 avg) | Ratio |
|---|---:|---:|---:|
| R0002 | 3.16% | 0.84% | 3.8x |
| R0003 | 4.24% | 0.61% | 7.0x |
| R0004 | 4.92% | 1.06% | 4.6x |
| R0005 | 5.44% | 1.10% | 5.0x |

3′ G→A is visibly present but much weaker/noisier than the 5′ signal (see right panel) — worth noting as-is rather than overselling; asymmetric 5′/3′ damage strength is itself a real, reportable pattern, not a data-quality problem.

**This is the load-bearing authentication result** — direct molecular evidence that recovered coffee DNA is genuinely of historical origin, independent of how little of it survived.

## Degradation is real and severe (pairs with the damage result)

- Endogenous DNA: under 1% of reads are *Coffea*-derived in every sample (rest is environmental/microbial — see `PIPELINE.md`'s "Sample QC: signal/coverage funnel" for the full funnel).
- Library complexity: only ~1,000–5,000 unique original DNA molecules recovered per sample (Picard `ESTIMATED_LIBRARY_SIZE`) — a hard ceiling independent of sequencing depth.
- Nuclear genome breadth of coverage: 0.01–0.03% (best sample R0002: ~365,000 of 1.2 billion bp have any data at all).

## Discussion: sample history and a proposed comparison

Samples were not sequenced directly from the wreck — they were held at Kokoelmakeskus for a number of years first. Visual comparison (beans looking paler/emptier than the collection-event photos) suggests possible continued degradation during storage, on top of whatever degradation occurred during the ~200 years submerged.

**Important framing point:** the genomic data here cannot by itself separate "degraded during submersion" from "degraded during post-excavation storage" — there's no freshly-excavated comparison point in this dataset. Don't claim storage caused degradation; the data doesn't support that causal claim on its own.

**Proposed discussion/future-work item (added on request):** collect a fresh sample directly from the Vrouw Maria wreck itself and sequence it alongside these Kokoelmakeskus-held samples, comparing endogenous DNA percentage (and ideally library complexity) between the two. This would be a direct, controlled test of whether post-excavation storage duration measurably affects recoverable genomic yield — a genuinely open question with real relevance for underwater heritage conservation protocols generally, not just this shipwreck. Frame as a proposed next step, not a result.

## Secondary result: trimming meaningfully improves recovery

Adding `fastp` adapter/quality trimming before alignment increased effective library complexity 66–161% across all 4 samples (not just cleaner alignment — genuinely more unique molecules recovered), likely because untrimmed adapter contamination on short fragments was causing true PCR duplicates to align to slightly different positions and escape duplicate-marking. Good, simple demonstration that careful bioinformatic processing matters even on severely degraded material. See `PIPELINE.md`'s 2026-09-19/21 entries and the git history in `visualization/` for the exact before/after numbers per sample.

## Honest limitation: cultivar identification not currently possible

Breadth of coverage (0.01–0.03% of the nuclear genome) is far short of what's needed to reliably hit the small, specifically-curated set of markers that distinguish closely related *Coffea arabica* cultivars like Typica and Bourbon (the species has famously low genetic diversity — nearly all commercial varieties trace to these two historical introductions, so distinguishing them requires known diagnostic positions, not just any variant). Chloroplast coverage is much better (~5% breadth, ~18x nuclear depth) but likely isn't informative for this specific question either, since Typica and Bourbon share a common maternal lineage.

Worth stating as a limitations/future-work point: targeted capture against a defined marker panel (e.g. the published Coffee 8.5K SNP array) would be a far more efficient use of limited sequencing effort than further genome-wide shotgun sequencing, if cultivar-level identification is a future goal.

## Deliberately left out

Metagenomic screening (Kraken2 classification of the unmapped fraction) — confirmed the >99% unmapped reads are contamination correctly excluded by alignment (mostly sediment/soil bacteria, plus a small fraction of low-complexity repeat sequences that don't carry real signal), not a surprising or poster-worthy result on its own. Full writeup lives in the separate `CW_metagenomic_screening` repo (`LABDIARY.md`) if needed for a methods appendix or reviewer question, but doesn't need poster space.
