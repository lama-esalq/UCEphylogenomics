import csv

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
