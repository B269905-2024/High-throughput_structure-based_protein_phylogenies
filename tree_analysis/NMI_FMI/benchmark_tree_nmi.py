import pandas as pd
from ete3 import Tree
from sklearn.metrics import normalized_mutual_info_score


#cath
cath_df = pd.read_csv("protein_to_cath.tsv", delim_whitespace=True, header=None, names=["pdb_chain", "syn_id", "cath"])
cath_df["syn_id"] = cath_df["syn_id"].astype(str).str.strip()
cath_df["cath"] = cath_df["cath"].astype(str).str.strip()

#tree
tree = Tree("full_p_value_JCVI_no_nan.nwk", format=1)
leaf_names = [leaf.name.strip() for leaf in tree.get_leaves()]

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
    y_true = []
    y_pred = []

    for i, leaf in enumerate(leaf_names):
        if leaf in id_to_cath:
            y_true.append(id_to_cath[leaf])
            y_pred.append(i)  # each leaf gets unique ID

    print(f"  Matching {len(y_true)} proteins.")

    if len(y_true) < 2:
        print("  ⚠️  Not enough data.\n")
        continue

    nmi = normalized_mutual_info_score(y_true, y_pred)
    print(f"  NMI: {nmi:.4f}\n")

