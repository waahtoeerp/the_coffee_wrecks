#!/usr/bin/env python3
"""
Builds the poster's damage-curve figure from mapDamage's per-sample
5pCtoT_freq.txt / 3pGtoA_freq.txt (in mapDamage-out/${SAMPLE}_mapDamage_dedup/,
i.e. the post-dedup, --rescale run -- deduplicated so PCR copies of one
damaged original molecule don't inflate the apparent signal).

Usage: python3 make_damage_plot.py
Run directly on the Roihu login node -- lightweight, no sbatch needed.
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE = "/scratch/project_2019675/the_coffee_wrecks"
SAMPLES = ["CT600-007R0002", "CT600-007R0003", "CT600-007R0004", "CT600-007R0005"]
COLORS = {"CT600-007R0002": "#2a78d6", "CT600-007R0003": "#d6822a",
          "CT600-007R0004": "#0ca30c", "CT600-007R0005": "#d03b3b"}

def read_freq(path):
    positions, freqs = [], []
    with open(path) as f:
        next(f)  # header
        for line in f:
            pos, val = line.strip().split("\t")
            positions.append(int(pos))
            freqs.append(float(val))
    return positions, freqs

fig, axes = plt.subplots(1, 2, figsize=(11, 4.5), sharey=True)

for sample in SAMPLES:
    d = os.path.join(BASE, "mapDamage-out", f"{sample}_mapDamage_dedup")
    p5, f5 = read_freq(os.path.join(d, "5pCtoT_freq.txt"))
    p3, f3 = read_freq(os.path.join(d, "3pGtoA_freq.txt"))
    axes[0].plot(p5, f5, marker="o", markersize=3, linewidth=1.6,
                 color=COLORS[sample], label=sample)
    axes[1].plot(p3, f3, marker="o", markersize=3, linewidth=1.6,
                 color=COLORS[sample], label=sample)

axes[0].set_title("5′ C→T (deamination at fragment start)", fontsize=11)
axes[1].set_title("3′ G→A (deamination at fragment end)", fontsize=11)
for ax in axes:
    ax.set_xlabel("Position from read end (bp)")
    ax.set_ylim(bottom=0)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.grid(axis="y", alpha=0.25)
axes[0].set_ylabel("Substitution frequency")
axes[1].legend(loc="upper right", fontsize=9, frameon=False)

fig.suptitle("Ancient-DNA deamination signature, all 4 samples (post-dedup)", fontsize=13, y=1.02)
fig.tight_layout()

out_png = os.path.join(BASE, "poster", "figures", "damage_curves_all_samples.png")
out_pdf = os.path.join(BASE, "poster", "figures", "damage_curves_all_samples.pdf")
fig.savefig(out_png, dpi=300, bbox_inches="tight")
fig.savefig(out_pdf, bbox_inches="tight")
print(f"Wrote {out_png}")
print(f"Wrote {out_pdf}")
