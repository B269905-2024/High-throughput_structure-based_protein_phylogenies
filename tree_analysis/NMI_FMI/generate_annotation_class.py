import pandas as pd

with open("annotation.tsv") as f:
    syn_list = [line.strip() for line in f]

cath_df = pd.read_csv("protein_to_cath.tsv", sep="\s+", header=None, names=["pdb", "syn", "cath"])
cath_df["class"] = cath_df["cath"].str.split(".").str[0]

unique_classes = sorted(cath_df["class"].unique())
class_to_color = {}
for i, cls in enumerate(unique_classes):
    intensity = int(255 - (i / (len(unique_classes) - 1)) * 200) if len(unique_classes) > 1 else 255
    hex_blue = f"#0000{intensity:02x}"
    class_to_color[cls] = hex_blue

syn_to_class = cath_df.set_index("syn")["class"].to_dict()
syn_to_color = {syn: class_to_color[cls] for syn, cls in syn_to_class.items()}

with open("annotation_class.tsv", "w") as out:
    for syn in syn_list:
        cls = syn_to_class.get(syn)
        color = syn_to_color.get(syn)
        if cls and color:
            out.write(f"{syn}\t{color}\t{cls}\n")
        else:
            out.write("\n")  #empty line if no syn 

