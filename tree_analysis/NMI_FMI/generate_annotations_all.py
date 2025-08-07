import pandas as pd
import colorsys

with open("annotation.tsv") as f:
    syn_list = [line.strip() for line in f]

cath_df = pd.read_csv("protein_to_cath.tsv", sep="\s+", header=None, names=["pdb", "syn", "cath"])
cath_df["class"] = cath_df["cath"].str.split(".").str[0]
cath_df["arch"] = cath_df["cath"].str.extract(r'^(\d+\.\d+)')[0]
cath_df["top"] = cath_df["cath"].str.extract(r'^(\d+\.\d+\.\d+)')[0]

#cluster colours
class_ids = sorted(cath_df["class"].dropna().unique())
base_hues = [0.0, 0.17, 0.33, 0.58, 0.75]  

class_to_hue = dict(zip(class_ids, base_hues))

def hsv_to_hex(h, s=0.9, v=0.9):
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return '#{:02x}{:02x}{:02x}'.format(int(r * 255), int(g * 255), int(b * 255))
#class
class_color_map = {cls: hsv_to_hex(class_to_hue[cls], 0.9, 0.9) for cls in class_ids}

#architecture
archs = sorted(cath_df["arch"].dropna().unique())
arch_color_map = {}
for cls in class_ids:
    class_archs = [a for a in archs if a.startswith(cls + ".")]
    for i, arch in enumerate(class_archs):
        s = 0.4 + 0.5 * (i / max(1, len(class_archs) - 1))  # 0.4 → 0.9
        arch_color_map[arch] = hsv_to_hex(class_to_hue[cls], s, 0.9)

#topology
tops = sorted(cath_df["top"].dropna().unique())
top_color_map = {}
for cls in class_ids:
    class_archs = [a for a in archs if a.startswith(cls + ".")]
    for arch in class_archs:
        arch_tops = [t for t in tops if t.startswith(arch + ".")]
        for i, top in enumerate(arch_tops):
            s = 0.7  #saturation stays the same
            v = 0.3 + 0.6 * (1 - i / max(1, len(arch_tops) - 1))  
            top_color_map[top] = hsv_to_hex(class_to_hue[cls], s, v)

cls_lookup = cath_df.set_index("syn")["class"].to_dict()
arch_lookup = cath_df.set_index("syn")["arch"].to_dict()
top_lookup = cath_df.set_index("syn")["top"].to_dict()

cls_color = {syn: class_color_map.get(cls_lookup[syn]) for syn in cls_lookup if cls_lookup[syn] in class_color_map}
arch_color = {syn: arch_color_map.get(arch_lookup[syn]) for syn in arch_lookup if arch_lookup[syn] in arch_color_map}
top_color = {syn: top_color_map.get(top_lookup[syn]) for syn in top_lookup if top_lookup[syn] in top_color_map}

def write_annotation(filename, syn_list, value_lookup, color_lookup):
    with open(filename, "w") as f:
        for syn in syn_list:
            val = value_lookup.get(syn)
            color = color_lookup.get(syn)
            if val and color:
                f.write(f"{syn}\t{color}\t{val}\n")
            else:
                f.write("\n")

write_annotation("annotation_class.tsv", syn_list, cls_lookup, cls_color)
write_annotation("annotation_arch.tsv", syn_list, arch_lookup, arch_color)
write_annotation("annotation_top.tsv", syn_list, top_lookup, top_color)

