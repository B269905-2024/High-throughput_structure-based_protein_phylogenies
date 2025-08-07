import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("protein_to_cath.tsv", sep=' ', header=None, names=["pdb", "protein", "cath"])

df["Class"] = df["cath"].apply(lambda x: x.split(".")[0])
df["Architecture"] = df["cath"].apply(lambda x: ".".join(x.split(".")[:2]))
df["Topology"] = df["cath"].apply(lambda x: ".".join(x.split(".")[:3]))
df["Homologous"] = df["cath"]

group_counts = {
    "Class": df["Class"].value_counts().sort_values(ascending=False),
    "Architecture": df["Architecture"].value_counts().sort_values(ascending=False),
    "Topology": df["Topology"].value_counts().sort_values(ascending=False),
    "Homologous Superfamily": df["Homologous"].value_counts().sort_values(ascending=False)
}

#plot
fig, axs = plt.subplots(2, 2, figsize=(12, 8))
axs = axs.flatten()

for idx, (ax, (level, counts)) in enumerate(zip(axs, group_counts.items())):
    bars = ax.bar(range(len(counts)), counts.values)
    ax.set_title(f"{level} Level")
    ax.set_xlabel("Group Index")
    ax.set_ylabel("Protein Count")
    ax.tick_params(labelbottom=False)

    for i, bar in enumerate(bars):
        height = bar.get_height()
        if idx < 2 or i % 5 == 0:
            fontsize = 8 if idx < 2 else 6
            ax.annotate(f'{height}', xy=(bar.get_x() + bar.get_width() / 2, height),
                        xytext=(0, 2), textcoords="offset points", ha='center', fontsize=fontsize)

    group_count = len(counts)
    ax.legend([f"{level}: {group_count} groups"], loc='upper right', fontsize=8, frameon=False)

plt.tight_layout()
plt.savefig("cath_group_sizes.png", dpi=300, format='png')
plt.show()

