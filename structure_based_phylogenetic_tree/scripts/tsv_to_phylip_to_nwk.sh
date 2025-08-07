#!/bin/bash

input_file="/exports/eddie/scratch/s2713107/p_value_mat/full_p_value_JCVI_no_nan.tsv"
output_file="/exports/eddie/scratch/s2713107/p_value_mat/full_p_value_JCVI_no_nan.phylip"

#input_file="full_p_value_JCVI_no_nan.tsv"
#output_file="full_p_value_JCVI_no_nan.phylip"

read -r header < "$input_file"
num_proteins=$(echo "$header" | awk '{print NF - 1}')

echo "$num_proteins" > "$output_file"

tail -n +2 "$input_file" | while IFS=$'\t' read -r row; do
  protein=$(echo "$row" | cut -f1)
  label=$(printf "%-10s" "$protein" | cut -c1-10)

  values=$(echo "$row" | cut -f2- | sed 's/\t/ /g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
  values=$(echo "$values" | awk '{
    for (i=1; i<=NF; i++) {
      if ($i == "") $i = "0.00000";
      printf "%s ", $i;
    }
    print ""
  }')

  echo "$label $values" >> "$output_file"
done

(base) s2713107@titan:~/matrix_analysis$
(base) s2713107@titan:~/matrix_analysis$ vim tsv_to_phylip.sh
(base) s2713107@titan:~/matrix_analysis$ cat tsv_to_phylip.sh
#!/bin/bash

########tsv to phylip
#input_file="full_p_value_JCVI_no_nan.tsv"
#output_file="full_p_value_JCVI_no_nan.phylip"

input_file="$1"
output_file="$2"
tree_file="$3"


#num proteins
read -r header < "$input_file"
num_proteins=$(echo "$header" | awk '{print NF - 1}')

echo "$num_proteins" > "$output_file"

#rows
tail -n +2 "$input_file" | while IFS=$'\t' read -r row; do
  protein=$(echo "$row" | cut -f1)
  label=$(printf "%-10s" "$protein" | cut -c1-10)

  values=$(echo "$row" | cut -f2- | sed 's/\t/ /g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
  values=$(echo "$values" | awk '{
    for (i=1; i<=NF; i++) {
      if ($i == "") $i = "0.00000";
      printf "%s ", $i;
    }
    print ""
  }')

  echo "$label $values" >> "$output_file"
done


##########make a tree
quicktree -in m "$output_file" > "$tree_file"

#quicktree -in m full_p_value_JCVI_no_nan.phylip > full_p_value_JCVI_no_nan.nwk

