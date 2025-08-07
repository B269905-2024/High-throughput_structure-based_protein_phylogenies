#!/bin/bash

#!/bin/bash
#Script to combine rows obtained with matrix_array_job.sh

#$ -N combine_rows              
#$ -cwd                         
#$ -l h_rt=00:30:00             
#$ -l h_vmem=8G                 
#$ -m bea                       
#$ -M s2713107@ed.ac.uk        

#load modules
. /etc/profile.d/modules.sh     
module load anaconda           

#dirs
INPUT_DIR=/exports/eddie/scratch/s2713107/p_value_mat_par/JCVI-syn3A_unrelaxed_pdbs_1507/rows
MATRIX_FILE="/exports/eddie/scratch/s2713107/p_value_mat_par/JCVI-syn3A_unrelaxed_pdbs_1507/rows/matrix.tsv"
MISSING_ROWS_FILE="/exports/eddie/scratch/s2713107/p_value_mat_par/JCVI-syn3A_unrelaxed_pdbs_1507/rows/missing_rows.txt"
NAN_ROWS_FILE="/exports/eddie/scratch/s2713107/p_value_mat_par/JCVI-syn3A_unrelaxed_pdbs_1507/rows/nan_rows.txt"

declare -a ROW_NUMBERS
declare -a ALL_SYN_IDS
declare -A MATRIX
declare -a MISSING_ROWS
declare -a NAN_ROWS

cd "$INPUT_DIR" || exit

for file in row_*.txt; do
    num=${file//[^0-9]/}
    ROW_NUMBERS+=($num)
done

IFS=$'\n' ROW_NUMBERS=($(sort -n <<<"${ROW_NUMBERS[*]}")) #sort by row number
unset IFS

#missing rows
if [ ${#ROW_NUMBERS[@]} -gt 0 ]; then
    min_row=${ROW_NUMBERS[0]}
    max_row=${ROW_NUMBERS[-1]}

    for ((i=min_row; i<=max_row; i++)); do
        if [[ ! " ${ROW_NUMBERS[@]} " =~ " $i " ]]; then
            MISSING_ROWS+=("row_$i.txt")
        fi
    done
else
    echo "no rows in $INPUT_DIR"
    exit 1
fi

#matrix construction
for row_num in "${ROW_NUMBERS[@]}"; do
    file="row_$row_num.txt"
    
    if [[ ! -f "$file" ]]; then
        MISSING_ROWS+=("$file")
        continue
    fi
    
    read -r line < "$file"
    
    IFS=' ' read -ra VALUES <<< "$line"
    syn_id="${VALUES[0]}"
    if [[ "$row_num" -eq 1 ]]; then
        for ((i=1; i<${#VALUES[@]}; i++)); do
            ALL_SYN_IDS+=("${VALUES[$i]}")
        done
    fi
    
    if [[ "$line" =~ [Nn][Aa][Nn] ]]; then #check for nans
        NAN_ROWS+=("$file")
        continue
    fi
    
    for ((i=1; i<${#VALUES[@]}; i++)); do
        MATRIX["$row_num,$((i-1))"]="${VALUES[$i]}"
    done
done

#missing rows and nans
printf "%s\n" "${MISSING_ROWS[@]}" > "$MISSING_ROWS_FILE"
printf "%s\n" "${NAN_ROWS[@]}" > "$NAN_ROWS_FILE"

#create tsv
{
    printf "row_id\t"
    printf "%s\t" "${ALL_SYN_IDS[@]}"
    printf "\n"
    
    for row_num in "${ROW_NUMBERS[@]}"; do
        if [[ " ${MISSING_ROWS[@]} " =~ " row_${row_num}.txt " ]] || 
           [[ " ${NAN_ROWS[@]} " =~ " row_${row_num}.txt " ]]; then
            continue
        fi
        
        printf "row_%s\t" "$row_num"
        
        #colmuns
        for ((col=0; col<${#ALL_SYN_IDS[@]}; col++)); do
            key="$row_num,$col"
            printf "%s\t" "${MATRIX[$key]}"
        done
        
        printf "\n"
    done
} > "$MATRIX_FILE"

echo "Processed: $INPUT_DIR"
echo "Matrix created: $MATRIX_FILE"
echo "Missing rows: $MISSING_ROWS_FILE"
echo "Rows with NaN values: $NAN_ROWS_FILE"
