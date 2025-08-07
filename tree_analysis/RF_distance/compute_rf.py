from ete3 import Tree

tree1 = Tree("full_p_value_JCVI_no_nan_0.nwk", format=1)
tree2 = Tree("needle_distance_matrix_no_nan.nwk", format=1)

tree1.unroot()
tree2.unroot()

rf, max_rf, common_leaves, parts_t1, parts_t2, discarded_t1, discarded_t2 = tree1.robinson_foulds(tree2, unrooted_trees=True)

print(f"rf distance: {rf}")
print(f"max rf distance: {max_rf}")
print(f"normalisedc rf distance: {rf / max_rf:.4f}")
print(f"discarded leaves 1: {discarded_t1}")
print(f"discarded leaves 2: {discarded_t2}")

