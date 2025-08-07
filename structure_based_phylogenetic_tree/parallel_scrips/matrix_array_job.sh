#!/bin/bash
#$ -N m_mycoides_array_job                #job name
#$ -cwd                                   #run in current dir
#$ -t 1-457                                #num of tasks
#$ -l h_rt=48:00:00                       #max duration
#$ -l h_vmem=8G                           #request memory
#$ -o /exports/eddie/scratch/sxxxxxx/p_value_mat_par/logs/output_matcha_$TASK_ID.log #outputs
#$ -e /exports/eddie/scratch/sxxxxxx/p_value_mat_par/logs/error_matcha_$TASK_ID.log  #error outputs
#$ -m a                               #notifications
#$ -M s2713107@ed.ac.uk                #email

#module and enviroment
. /etc/profile.d/modules.sh
module load anaconda
conda activate /exports/eddie/scratch/sxxxxxx/envs/fatcat

#input dir
#input_dir="/exports/eddie/scratch/sxxxxxxx/10_pdb_subset"
input_dir="/exports/eddie/scratch/sxxxxxx/JCVI-syn3A_unrelaxed_pdbs"
folder_name="${input_dir##*/}"

#create job id
#job_id=$(date +"%d%m%H%M")
job_id=$(date +"%d%m")

#output dirs
output_base_dir="/exports/eddie/scratch/sxxxxxx/p_value_mat_par/${folder_name}_${job_id}"
output_dir="${output_base_dir}/alignments"
rows_dir="${output_base_dir}/rows"
csv_dir="${output_base_dir}/csvs"
results_dir="${output_base_dir}/results"
log_dir="${output_base_dir}/logs"

mkdir -p "$output_dir" "$rows_dir" "$csv_dir" "$results_dir" "$log_dir"

#run fatcat on each row
bash run_fatcat_row.sh "$job_id" "$output_base_dir"

