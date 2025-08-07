import pandas as pd
from ete3 import Tree
from scipy.cluster.hierarchy import linkage, fcluster
from scipy.spatial.distance import squareform
import numpy as np
from sklearn.metrics import fowlkes_mallows_score


#cath mapping
cath_df = pd.read_csv("protein_to_cath.tsv", sep=r"\s+", header=None, names=["pdb_chain", "syn_id", "cath"])
cath_df["syn_id"] = cath_df["syn_id"].astype(str).str.strip()
cath_df["cath"] = cath_df["cath"].astype(str).str.strip()

#tree
tree = Tree("full_p_value_JCVI_no_nan.nwk", format=1)
leaf_names = [leaf.name.strip() for leaf in tree.get_leaves()]
leaf_index = {name: i for i, name in enumerate(leaf_names)}

cath_levels = {
    "Class": 1,
    "Architecture": 2,
    "Topology": 3
}

for level_name, level_depth in cath_levels.items():
    print(f"## {level_name} level ##")

    df_non_missing = cath_df.dropna(subset=["cath"]).copy()
    df_non_missing[f"cath_{level_name.lower()}"] = df_non_missing["cath"].apply(
        lambda x: ".".join(x.split(".")[:level_depth])
    )

    id_to_cath = dict(zip(df_non_missing["syn_id"], df_non_missing[f"cath_{level_name.lower()}"]))

    common_ids = [leaf for leaf in leaf_names if leaf in id_to_cath]

    n = len(common_ids)
    dist_matrix = np.zeros((n, n))

    for i in range(n):
        for j in range(i + 1, n):
            d = tree.get_distance(common_ids[i], common_ids[j])
            dist_matrix[i, j] = d
            dist_matrix[j, i] = d

    #cluster
    Z = linkage(squareform(dist_matrix), method="average")
    true_labels = [id_to_cath[i] for i in common_ids]
    k = len(set(true_labels))
    pred_clusters = fcluster(Z, k, criterion="maxclust")

    fmi = fowlkes_mallows_score(true_labels, pred_clusters)

    print(f"fmi: {fmi:.4f}\n")

