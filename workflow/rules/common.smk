import csv

dataset = config["match_contigs"]["taxon-set_name"]

SAMPLES = []
R1 = {}
R2 = {}
LAYOUT = {}

with open(config["samples"]) as fh:
    reader = csv.DictReader(fh)
    for row in reader:
        sample = row["sample"]
        SAMPLES.append(sample)
        R1[sample] = row["r1"]
        R2[sample] = row["r2"]
        LAYOUT[sample] = row["layout"]

wildcard_constraints:
    sample = r"[^/\.]+",
    dataset = r"[^/\.]+"

from pathlib import Path

def matched_samples(fasta):
    samples = set()
    with open(fasta) as fin:
        for line in fin:
            if line.startswith(">"):
                header = line[1:].split()[0]
                sample = header.split("_",1)[1]
                samples.add(sample)
    return sorted(samples)

def exploded_fastas(wildcards):
    ckpt = checkpoints.explode_fastas.get(dataset=wildcards.dataset)
    folder = ckpt.output[0]
    return sorted(Path(folder).glob("*.unaligned.fasta"))
