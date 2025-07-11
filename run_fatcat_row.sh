#!/bin/bash

job_id=$1
output_base_dir=$2

#inputs
input_dir="/exports/eddie/scratch/s2713107/10_pdb_subset"
protein_ids="protein_IDs.txt"
files=("$input_dir"/*.pdb)

#row indexes
row_idx=$((SGE_TASK_ID - 1))
row_id=$SGE_TASK_ID

protein_name=$(awk -v id="$row_id" '$1 == id {print $2}' "$protein_ids")

echo "running row $row_idx ($protein_name)"

#loop over all proteins
pvalues=""
for ((j=0; j<${#files[@]}; j++)); do
    pdb_file="${files[j]}"
    target_name=$(awk -v id=$((j+1)) '$1 == id {print $2}' "$protein_ids")
    echo -e "target: ${target_name} pdb file: ${pdb_file}"
    prefix="${protein_name}_${target_name}"
    echo -e "prefix: ${prefix}"
    ls 
    #DEBUG
    echo -e "does pdb exist?"
    ls -l "${input_dir}/${protein_name}.pdb"
    echo -e "\n header"
    cat "${input_dir}/${protein_name}.pdb" | head -5
    

# Run FATCAT alignment
    #FATCAT -p1 "${input_dir}/${protein_name}.pdb" -p2 "$pdb_file" -o "$aln_output" -m -ac -t > /dev/null 2>&1
    #echo -e "fatcat command: FATCAT -p1 ${input_dir}/${protein_name}.pdb -p2 $pdb_file -o ${prefix} -m -ac -t "
    #FATCAT -p1 "${input_dir}/${protein_name}.pdb" -p2 "$pdb_file" -o "${prefix}" -m -ac -t
    #echo -e "POST FATCAT DIR CONETNETS"
    #ls

    #pdb kopiowanie do current dir
    pdb_file_extracted="${pdb_file##*/}"
    cp "${input_dir}/${protein_name}.pdb" "$pdb_file" .
    echo -e "ls BEFORE FATCAT"
    ls
    FATCAT -p1 "${protein_name}.pdb" -p2 "${pdb_file_extracted}" -o "${prefix}" -m -ac -t
    echo -e "FATCAT COMMAND: FATCAT -p1 ${protein_name}.pdb -p2 $pdb_file_extracted -o ${prefix} -m -ac -t"
    echo -e "POST FATCAT DIR CONETNETS"
    ls
            
    mv "${protein_name}_${target_name}"* "${output_base_dir}/alignments"   
    echo -e "mv ${protein_name}_${target_name}* ${output_base_dir}/alignments"        
    raw_score=$(grep -oP "Score \K[\d.]+" "${output_base_dir}/alignments/${prefix}.aln" || echo "Nan")
    pvalue=$(grep -oP "P-value \K[\d.e+-]+" "${output_base_dir}/alignments/${prefix}.aln" || echo "Nan")
    aln_len=$(grep -oP "align-len \K[\d.e+-]+" "${output_base_dir}/alignments/${prefix}.aln" || echo "Nan")

    echo "raw score: ${raw_score}, p-value: ${pvalue}, alignment: ${aln_len}"
    rm -fr "${protein_name}.pdb" "${pdb_file_extracted}"

    #pvalue=$(grep -i "P-value" "$aln_output" | awk '{print $NF}')
    [[ -z "$pvalue" ]] && pvalue="NaN"

    pvalues+="$pvalue "
done

#row output
echo "$protein_name $pvalues" > "${output_base_dir}/rows/row_${row_id}.txt"

#csv output
echo "$protein_name,$(echo $pvalues | tr ' ' ',')" > "${output_base_dir}/csvs/row_${row_id}.csv"

echo "Row $row_id done: ${output_base_dir}/rows/row_${row_id}.txt"

