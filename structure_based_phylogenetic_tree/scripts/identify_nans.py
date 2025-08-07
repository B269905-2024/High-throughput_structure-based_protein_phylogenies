import csv
import math
from collections import defaultdict

####################identify nans
#file_path = "full_p_value_JCVI.tsv"
file_path = snakemake.input[0]
nan_pairs = []

with open(file_path, newline='') as tsvfile:
    reader = csv.reader(tsvfile, delimiter='\t')
    header = next(reader)
    protein_names = header[1:]

    for row in reader:
        row_protein = row[0]
        for col_index, value in enumerate(row[1:]): #skip index
            if value.strip().lower() == "nan":
                col_protein = protein_names[col_index]
                nan_pairs.append([col_protein, row_protein])

#print(nan_pairs)

#############count occurneces

count_dict = defaultdict(int)
for pair in nan_pairs:
    for protein in pair:
        count_dict[protein] += 1

if all(map(lambda x: x % 2 == 0, count_dict.values())):
    halved_counts = {k: (lambda v: v // 2)(v) for k, v in count_dict.items()}
    #print(halved_counts)
else:
    print("\nnon-symmetric matrix")

#print(nan_pairs)
#print(dict(count_dict))
######################identify proteins to remove
proteins_to_remove = set()

if 'halved_counts' in locals():
    for pair in nan_pairs:
        p1, p2 = pair
        if halved_counts.get(p1, 0) > 1 or halved_counts.get(p2, 0) > 1:
            if halved_counts.get(p1, 0) > 1:
                proteins_to_remove.add(p1)
            if halved_counts.get(p2, 0) > 1:
                proteins_to_remove.add(p2)
        else:
            proteins_to_remove.add(p1)
            proteins_to_remove.add(p2)

    #print("\nProteins to remove:")
    #print(proteins_to_remove)
else:
    print("\nmatrix is not symmetric, no nans removed - check whats wrong with the tsv file")
####################################remove nans

if halved_counts:
    input_file = file_path 
    output_file = snakemake.output[0]
    #input_file = "full_p_value_JCVI.tsv" #this to be changed in the snakemake file
    #output_file = "full_p_value_JCVI_no_nani_test.tsv"

    with open(input_file, newline='') as f_in, open(output_file, 'w', newline='') as f_out:
        reader = csv.reader(f_in, delimiter='\t')
        writer = csv.writer(f_out, delimiter='\t')

        header = next(reader)
        colnames = header
        keep_indices = [i for i, name in enumerate(colnames) if name not in proteins_to_remove]

        new_header = [colnames[i] for i in keep_indices]
        writer.writerow(new_header)

        for row in reader:
            row_label = row[0]
            if row_label in proteins_to_remove:
                continue
            new_row = [row[i] for i in keep_indices]
            writer.writerow(new_row)

    print(f"\n file without nans saved as: {output_file}")

    ####################check again if marix is symmetric just to be safe

def is_symmetric_tsv(file_path):
    with open(file_path, newline='') as f:
        reader = csv.reader(f, delimiter='\t')
        header = next(reader)
        proteins = header[1:]
        matrix = []
        row_labels = []
        for row in reader:
            row_labels.append(row[0])
            matrix.append(row[1:])

        if proteins != row_labels:
            return False

        n = len(matrix)
        for i in range(n):
            for j in range(n):
                if matrix[i][j] != matrix[j][i]:
                    return False
        return True

if is_symmetric_tsv(output_file):
    print("matrix is symmetric.")
else:
    print("matrix isn't symmetric.")
