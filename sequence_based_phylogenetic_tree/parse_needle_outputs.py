import os, re, csv
from collections import defaultdict

input_dir = "/exports/eddie/scratch/sxxxxxx/JCVI_needle/raw_outputs_needle"
output_matrix = "/exports/eddie/scratch/sxxxxxx/JCVI_needle/needle_distance_matrix.tsv"
output_log = "/exports/eddie/scratch/sxxxxxx/JCVI_needle/needle_identity_log.csv"

pairwise_identity = {}
proteins = set()

for filename in os.listdir(input_dir):
    if filename.endswith(".needle"):
        parts = filename.replace(".needle", "").split("__")
        if len(parts) != 2:
            continue
        p1, p2 = parts
        proteins.update([p1, p2])
        with open(os.path.join(input_dir, filename)) as f:
            for line in f:
                if line.startswith("# Identity:"):
                    match = re.search(r"\(([\d\.]+)%\)", line)
                    if match:
                        identity = float(match.group(1)) / 100
                        pairwise_identity[tuple(sorted([p1, p2]))] = 1 - identity
                    break

proteins = sorted(proteins)
matrix = defaultdict(dict)
for p1 in proteins:
    for p2 in proteins:
        if p1 == p2:
            matrix[p1][p2] = 0.0
        else:
            key = tuple(sorted([p1, p2]))
            matrix[p1][p2] = pairwise_identity.get(key, "NaN")

with open(output_matrix, "w") as f:
    writer = csv.writer(f, delimiter="\t")
    writer.writerow([""] + proteins)
    for p1 in proteins:
        row = [p1] + [matrix[p1][p2] for p2 in proteins]
        writer.writerow(row)

with open(output_log, "w") as f:
    writer = csv.writer(f)
    writer.writerow(["Protein1", "Protein2", "Distance"])
    for (p1, p2), d in pairwise_identity.items():
        writer.writerow([p1, p2, d])

