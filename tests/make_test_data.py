#!/usr/bin/env python3
"""
Build a tiny test dataset for the base pipeline smoke test.

Takes a short slice of the real reference (real sequence, so the aligner and
GATK behave normally), and simulates paired reads from it with ancient-DNA-like
damage and adapter read-through. The point is that every stage runs, not that
the calls are biologically meaningful.

Writes, under OUT_ROOT:
  ref/test_ref.fna                                   the slice (one contig)
  vrouw_maria_2026_segments/Unknown_<SAMPLE>_{1,2}.fq.gz
  samples.tsv                                        one row, paths relative to OUT_ROOT

Usage: make_test_data.py <FULL_REF_FASTA> <OUT_ROOT> [--sample TEST01] [--pairs 3000]
                         [--region-bp 60000] [--seed 1]
"""
import argparse
import gzip
import os
import random

ADAPTER = "AGATCGGAAGAGC"
READ_LEN = 75
COMP = str.maketrans("ACGTN", "TGCAN")


def first_contig(path, region_bp):
    header, seq = None, []
    with open(path) as f:
        for line in f:
            line = line.rstrip("\n")
            if line.startswith(">"):
                if header is not None:
                    break
                header = line[1:].split()[0]
                continue
            seq.append(line.strip().upper())
            if sum(len(s) for s in seq) >= region_bp:
                break
    if header is None:
        raise SystemExit(f"no sequence in {path}")
    return header, "".join(seq)[:region_bp]


def revcomp(s):
    return s.translate(COMP)[::-1]


def deaminate(read, rng):
    bases = list(read)
    for i in range(min(10, len(bases))):
        if bases[i] == "C" and rng.random() < 0.35 * (0.7 ** i):
            bases[i] = "T"
    for j in range(min(10, len(bases))):
        if bases[-1 - j] == "G" and rng.random() < 0.35 * (0.7 ** j):
            bases[-1 - j] = "A"
    return "".join(bases)


def sequencing_errors(read, rng, rate=0.005):
    bases = list(read)
    for i in range(len(bases)):
        if rng.random() < rate:
            bases[i] = rng.choice([b for b in "ACGT" if b != bases[i]])
    return "".join(bases)


def to_read(fragment):
    read = fragment[:READ_LEN]
    if len(read) < READ_LEN:
        read = (read + ADAPTER)[:READ_LEN]
    return read


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ref")
    ap.add_argument("out_root")
    ap.add_argument("--sample", default="TEST01")
    ap.add_argument("--pairs", type=int, default=3000)
    ap.add_argument("--region-bp", type=int, default=60000)
    ap.add_argument("--seed", type=int, default=1)
    args = ap.parse_args()

    rng = random.Random(args.seed)
    contig, genome = first_contig(args.ref, args.region_bp)
    usable = len(genome) - 200

    ref_dir = os.path.join(args.out_root, "ref")
    reads_dir = os.path.join(args.out_root, "vrouw_maria_2026_segments")
    os.makedirs(ref_dir, exist_ok=True)
    os.makedirs(reads_dir, exist_ok=True)

    with open(os.path.join(ref_dir, "test_ref.fna"), "w") as f:
        f.write(f">{contig}\n")
        for i in range(0, len(genome), 80):
            f.write(genome[i:i + 80] + "\n")

    r1_path = os.path.join(reads_dir, f"Unknown_{args.sample}_1.fq.gz")
    r2_path = os.path.join(reads_dir, f"Unknown_{args.sample}_2.fq.gz")
    written = 0
    with gzip.open(r1_path, "wt") as f1, gzip.open(r2_path, "wt") as f2:
        for n in range(args.pairs):
            start = rng.randrange(0, usable)
            frag_len = max(30, min(150, int(rng.expovariate(1 / 50))))
            fragment = genome[start:start + frag_len]
            if "N" in fragment:
                continue
            r1 = sequencing_errors(deaminate(to_read(fragment), rng), rng)
            r2 = sequencing_errors(deaminate(to_read(revcomp(fragment)), rng), rng)
            q = "I" * len(r1)
            f1.write(f"@TEST:{n}/1\n{r1}\n+\n{q}\n")
            f2.write(f"@TEST:{n}/2\n{r2}\n+\n{q}\n")
            written += 1

    with open(os.path.join(args.out_root, "samples.tsv"), "w") as f:
        f.write("sample_id\tread1\tread2\n")
        f.write(f"{args.sample}\t"
                f"vrouw_maria_2026_segments/Unknown_{args.sample}_1.fq.gz\t"
                f"vrouw_maria_2026_segments/Unknown_{args.sample}_2.fq.gz\n")

    print(f"test data: {written} read pairs from {len(genome)} bp of {contig} -> {args.out_root}")


if __name__ == "__main__":
    main()
