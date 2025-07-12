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

csv_output="${output_base_dir}/csvs/alignment_results.csv" #raw score, p value, aln len
row_csv="${output_base_dir}/csvs/row_${row_id}_duration_memory.csv" #memory and duration
echo "protein_1,protein2,raw_score,p_value,aln_len" > "$csv_output"

#memory and usage
row_total_duration=0
row_max_memory=0



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
    #cat "${input_dir}/${protein_name}.pdb" | head -5
    

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
    #FATCAT -p1 "${protein_name}.pdb" -p2 "${pdb_file_extracted}" -o "${prefix}" -m -ac -t
    { /usr/bin/time -v FATCAT -p1 "${protein_name}.pdb" -p2 "${pdb_file_extracted}" -o "${prefix}" -m -ac -t ; } 2> "${prefix}_time.log"
    echo -e "FATCAT COMMAND: FATCAT -p1 ${protein_name}.pdb -p2 $pdb_file_extracted -o ${prefix} -m -ac -t"
    echo -e "POST FATCAT DIR CONETNETS"
    ls
##############################################
#    duration_sec=$(grep "Elapsed (wall clock) time" "${prefix}_time.log" | awk '{split($5,t,":"); if (length(t)==3) sec=t[1]*3600+t[2]*60+t[3]; else sec=t[1]*60+t[2]; print sec}')
 #   max_mem=$(grep "Maximum resident set size" "${prefix}_time.log" | awk '{print $6}')

  #  echo -e "Duration (sec): ${duration_sec}, Max memory (KB): ${max_mem}"

   # row_total_duration=$(echo "$row_total_duration + $duration_sec" | bc)
    #if [ "$max_mem" -gt "$row_max_memory" ]; then
    #    row_max_memory=$max_mem
   # fi


    duration_str=$(grep "Elapsed (wall clock) time" "${prefix}_time.log" | awk -F': ' '{print $2}')
    duration_sec=$(echo "$duration_str" | awk -F: '{
    if (NF==3) sec=$1*3600+$2*60+$3;
    else if (NF==2) sec=$1*60+$2;
    else sec=$1;
    print sec
    }')
    max_mem=$(grep "Maximum resident set size" "${prefix}_time.log" | awk '{print $6}')

    echo -e "Duration (sec): ${duration_sec}, Max memory (KB): ${max_mem}"

    if [ -n "$duration_sec" ]; then
	    row_total_duration=$(echo "$row_total_duration + $duration_sec" | bc)
    fi

    if [ -n "$max_mem" ]; then
	    if [ "$max_mem" -gt "$row_max_memory" ]; then
		    row_max_memory=$max_mem
	    fi
    fi
    echo -e "DEBUG: row max memory = ${row_max_memory}"

            
    #####################
    mv "${protein_name}_${target_name}"* "${output_base_dir}/alignments"   
    echo -e "mv ${protein_name}_${target_name}* ${output_base_dir}/alignments"        
    raw_score=$(grep -oP "Score \K[\d.]+" "${output_base_dir}/alignments/${prefix}.aln" || echo "Nan")
    pvalue=$(grep -oP "P-value \K[\d.e+-]+" "${output_base_dir}/alignments/${prefix}.aln" || echo "Nan")
    aln_len=$(grep -oP "align-len \K[\d.e+-]+" "${output_base_dir}/alignments/${prefix}.aln" || echo "Nan")
    echo "${protein_name},${target_name},${raw_score},${pvalue},${aln_len}" >> "$csv_output"

    echo "raw score: ${raw_score}, p-value: ${pvalue}, alignment: ${aln_len}"
    rm -fr "${protein_name}.pdb" "${pdb_file_extracted}"

    #pvalue=$(grep -i "P-value" "$aln_output" | awk '{print $NF}')
    [[ -z "$pvalue" ]] && pvalue="NaN"

    pvalues+="$pvalue "
done

#memory and duration stats
echo "" >> "$row_csv"
echo "row_total_duration_sec,row_max_memory_kb" >> "$row_csv"
echo "${row_total_duration},${row_max_memory}" >> "$row_csv"

#row output
echo "$protein_name $pvalues" > "${output_base_dir}/rows/row_${row_id}.txt"

echo "Row $row_id done: ${output_base_dir}/rows/row_${row_id}.txt"

