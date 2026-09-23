#!/usr/bin/env python3
"""
Builds the poster's damage-curve figure from mapDamage's per-sample
5pCtoT_freq.txt / 3pGtoA_freq.txt (in mapDamage-out/${SAMPLE}_mapDamage_dedup/,
i.e. the post-dedup, --rescale run -- deduplicated so PCR copies of one
damaged original molecule don't inflate the apparent signal).

Standard aDNA misincorporation-plot convention: C->T (5' end) in red,
G->A (3' end) in blue, both on the same axes per sample -- one panel per
sample, all 4 samples in a single row.

Usage: python3 make_damage_plot.py
Run directly on the Roihu login node -- lightweight, no sbatch needed.
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE = "/scratch/project_2019675/the_coffee_wrecks"
SAMPLES = ["CT600-007R0002", "CT600-007R0003", "CT600-007R0004", "CT600-007R0005"]
CTOT_COLOR = "#d0342c"  # red
GTOA_COLOR = "#2a5db0"  # blue

def read_freq(path):
    positions, freqs = [], []
    with open(path) as f:
        next(f)  # header
        for line in f:
            pos, val = line.strip().split("\t")
            positions.append(int(pos))
            freqs.append(float(val))
    return positions, freqs

fig, axes = plt.subplots(1, 4, figsize=(16, 3.2), sharex=True, sharey=True)

for ax, sample in zip(axes, SAMPLES):
    d = os.path.join(BASE, "mapDamage-out", f"{sample}_mapDamage_dedup")
    p5, f5 = read_freq(os.path.join(d, "5pCtoT_freq.txt"))
    p3, f3 = read_freq(os.path.join(d, "3pGtoA_freq.txt"))
    ax.plot(p5, f5, color=CTOT_COLOR, linewidth=1.8, label="C→T (5′ end)")
    ax.plot(p3, f3, color=GTOA_COLOR, linewidth=1.8, label="G→A (3′ end)")
    ax.set_title(sample, fontsize=11)
    ax.set_ylim(0, 0.06)
    ax.set_xlabel("Position (bp from read end)")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.grid(axis="y", alpha=0.2)

axes[0].set_ylabel("Substitution frequency")
axes[0].legend(loc="upper right", fontsize=9, frameon=False)
fig.suptitle("Ancient-DNA deamination signature (post-dedup)", fontsize=13)
fig.tight_layout(rect=[0, 0, 1, 0.96])

out_png = os.path.join(BASE, "poster", "figures", "damage_curves_all_samples.png")
out_pdf = os.path.join(BASE, "poster", "figures", "damage_curves_all_samples.pdf")
fig.savefig(out_png, dpi=300, bbox_inches="tight")
fig.savefig(out_pdf, bbox_inches="tight")
print(f"Wrote {out_png}")
print(f"Wrote {out_pdf}")
