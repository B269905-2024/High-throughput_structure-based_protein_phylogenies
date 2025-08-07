#!/bin/bash
#usage: ./p_value_matrix_non-array.sh <input_dir> <output_base_dir>
#$ -N non-parallel              
#$ -cwd                     
#$ -l h_rt=76:00:00             
#$ -l h_vmem=8G                 
#$ -m bea                       #begin, end, abort
#$ -M sxxxxxx@ed.ac.uk         

#load modules
. /etc/profile.d/modules.sh     
module load anaconda            

#activate env
conda activate /exports/eddie/scratch/s2713107/envs/fatcat
timestamp=$(date +"%H%M%d%m")
#job_id=$RANDOM_${timestamp}
job_id="snakemake"
echo "Job ID: $job_id"

#dirs and paths
input_dir="$1"
folder_name="${input_dir##*/}"
output_base_dir="$2"
output_dir="${output_base_dir}/alignments"
matrix_dir="${output_base_dir}/matrices"
log_dir="${output_base_dir}/logs"

mkdir -p "$output_base_dir"
mkdir -p "$output_dir"
mkdir -p "$matrix_dir"
mkdir -p "$log_dir"

log_file="${log_dir}/fatcat_timelog_ID$job_id.txt"
pvalue_matrix_file="${matrix_dir}/pvalue_matrix_ID$job_id.tsv"

echo "Pairwise Alignment FATCAT time log" > "$log_file"
echo "Job ID: $job_id" >> "$log_file"
echo "Format: protein1_protein2  START_TIME  END_TIME  DURATION_SEC" >> "$log_file"

#get pdbs
files=("$input_dir"/*.pdb)
num_files=${#files[@]}
num_alignments=0
total_time=0

if [ $num_files -eq 0 ]; then
    echo "no pdbs in $input_dir :("
    exit 1
fi

echo "$num_files pdb files found"

echo -n "Protein" > "$pvalue_matrix_file"
for ((i=0; i<num_files; i++)); do
    f=$(basename "${files[i]}" .pdb)
    echo -ne "\t$f" >> "$pvalue_matrix_file"
done
echo >> "$pvalue_matrix_file"

declare -A pvalue_matrix

#loop over each pair and print progress
#total_pairs=$((num_files * (num_files - 1) / 2)) #without self comparison
total_pairs=$((num_files * (num_files + 1) / 2))

current_pair=0

for ((i=0; i < num_files; i++)); do
    f1=$(basename "${files[i]}" .pdb)
    echo -n "$f1" >> "$pvalue_matrix_file"

    for ((j=0; j < num_files; j++)); do
        if [ $i -eq $j ]; then
            f2=$f1
        elif [ $j -lt $i ]; then
            f2=$(basename "${files[j]}" .pdb)
            echo -ne "\t${pvalue_matrix["$f2,$f1"]}" >> "$pvalue_matrix_file"
            continue
        else
            f2=$(basename "${files[j]}" .pdb)
        fi

        f2=$(basename "${files[j]}" .pdb)
        prefix="${f1}_${f2}"
        ((current_pair++))

        echo "Starting alignment $current_pair/$total_pairs: $prefix"
        start_time=$(date +%s)
        start_time_human=$(date '+%Y-%m-%d %H:%M:%S')
	
	#debugging
	echo "--------DEBUG INFO---------"
	#echo "path to prot 1: ${files[i]}"
	#cat ${files[i]} | head -10
	echo "path to prot 2: ${files[j]}"
	#cat ${files[j]} | head -10


	cp ${files[i]} .
	file_i="${files[i]##*/}"
	echo "file i is ${file_i}:"
	#cat ${file_i} | head -5

	cp ${files[j]} .
        file_j="${files[j]##*/}"
        echo "file j is ${file_j}:"
        #cat ${file_j} | head -5

	#echo -e "checking header..."
        #grep -E "^(HEADER|TITLE|COMPND|ATOM)" "$file_i"
	#grep -E "^(HEADER|TITLE|COMPND|ATOM)" "$file_j"
	
	echo -e "aligning ${file_i} and ${file_j}"
        #run fatcat and extract scores
	FATCAT -p1 "${file_i}" -p2 "${file_j}" -o "${prefix}" -m -ac -t 
	
	mv ${prefix}* "${output_dir}"
	echo -e "mv ${prefix}* ${output_dir}"
        raw_score=$(grep -oP "Score \K[\d.]+" "${output_dir}/${prefix}.aln" || echo "Nan")
        pvalue=$(grep -oP "P-value \K[\d.e+-]+" "${output_dir}/${prefix}.aln" || echo "Nan")
	aln_len=$(grep -oP "align-len \K[\d.e+-]+" "${output_dir}/${prefix}.aln" || echo "Nan")
	
	echo "raw score: ${raw_score}, p-value: ${pvalue}, alignment: ${aln_len}"
	
	rm -fr ${file_i} ${file_j}

	if [ -n "$output_dir" ] && [ -n "$prefix" ]; then
		rm -fr "${output_dir}/${prefix}"*
	else
		echo "prefix not set, files nit deleted!"
	fi


        #get num of atoms and residues in each prot
        atoms1=$(grep '^ATOM' "${files[i]}" | wc -l)
        residues1=$(grep '^ATOM' "${files[i]}" | grep ' CA ' | wc -l)
        atoms2=$(grep '^ATOM' "${files[j]}" | wc -l)
        residues2=$(grep '^ATOM' "${files[j]}" | grep ' CA ' | wc -l)
	#residues_avg=$( ("$residues1" + "$residues2") )
	residues_avg=$(echo "scale=2; ($residues1 + $residues2) / 2" | bc)
        {
        echo "Protein 1: $f1, Atoms: $atoms1, Residues: $residues1"
        echo "Protein 2: $f2, Atoms: $atoms2, Residues: $residues2"
        echo "P-value: $pvalue"
        echo "fatcat score: $raw_score"
	echo "Alignment length: $aln_len"
        } | tee -a results.txt
        
        #csv
	csv_file="${output_base_dir}/results.csv"

	if [ ! -f "$csv_file" ]; then
		echo "Protein1,Atoms1,Residues1,Protein2,Atoms2,Residues2,raw_FATCAT_score,P-value,aln_len" > "$csv_file"
	fi
	echo "$f1,$atoms1,$residues1,$f2,$atoms2,$residues2,$raw_score,$pvalue,$aln_len" >> "$csv_file"


        end_time=$(date +%s)
        end_time_human=$(date '+%Y-%m-%d %H:%M:%S')
        duration=$((end_time - start_time))
        echo "Finished alignment: $prefix in ${duration}s"

        echo -e "${prefix}\t${start_time_human}\t${end_time_human}\t${duration}" >> "$log_file"

        #save matrices
        pvalue_matrix["$f1,$f2"]=$pvalue

        echo -ne "\t$pvalue" >> "$pvalue_matrix_file"

        ((num_alignments++))
        total_time=$((total_time + duration))

    done
    echo >> "$pvalue_matrix_file"
done

#summary
echo -e "\nFATCAT Pairwise Comparison Summary" | tee -a "$log_file"
echo "job ID: $job_id" | tee -a "$log_file"
echo "input dir: $input_dir" | tee -a "$log_file"
echo "num  of PDB files: $num_files" | tee -a "$log_file"
echo "num of alignments: $num_alignments" | tee -a "$log_file"
echo "computation time: $total_time seconds" | tee -a "$log_file"

if [[ $num_alignments -gt 0 ]]; then
  avg_time=$(echo "scale=2; $total_time / $num_alignments" | bc)
  echo "avrg time per alignment: $avg_time s" | tee -a "$log_file"
fi

echo -e "\nresults saved in:" | tee -a "$log_file"
echo "1. alignment files: $output_dir" | tee -a "$log_file"
echo "2. p-value matrix: $pvalue_matrix_file" | tee -a "$log_file"
echo "3. log file: $log_file" | tee -a "$log_file"


