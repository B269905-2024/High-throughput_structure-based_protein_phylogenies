#!/bin/bash
#$ -N array_test_10                #job name
#$ -cwd                                   #run in current dir
#$ -t 1-457                                #num of tasks
#$ -l h_rt=03:00:00                       #max duration
#$ -l h_vmem=8G                           #request memory
#$ -o /exports/eddie/scratch/s2713107/p_value_mat_par/logs/output__mmycoides_yerba_$TASK_ID.log #outputs
#$ -e /exports/eddie/scratch/s2713107/p_value_mat_par/logs/error__mmycoidesyerba__$TASK_ID.log  #error outputs
#$ -m a                               #notifications
#$ -M s2713107@ed.ac.uk                #email

#module and enviroment
. /etc/profile.d/modules.sh
module load anaconda
conda activate /exports/eddie/scratch/s2713107/envs/fatcat

#input dir
#input_dir="/exports/eddie/scratch/s2713107/10_pdb_subset"
input_dir="/exports/eddie/scratch/s2713107/JCVI-syn3A_unrelaxed_pdbs"
folder_name="${input_dir##*/}"

#create job id
#job_id=$(date +"%d%m%H%M")
job_id=$(date +"%d%m%H")

#output dirs
output_base_dir="/exports/eddie/scratch/s2713107/p_value_mat_par/${folder_name}_${job_id}"
output_dir="${output_base_dir}/alignments"
rows_dir="${output_base_dir}/rows"
csv_dir="${output_base_dir}/csvs"
results_dir="${output_base_dir}/results"
log_dir="${output_base_dir}/logs"

mkdir -p "$output_dir" "$rows_dir" "$csv_dir" "$results_dir" "$log_dir"

#run fatcat on each row
bash run_fatcat_row.sh "$job_id" "$output_base_dir"

