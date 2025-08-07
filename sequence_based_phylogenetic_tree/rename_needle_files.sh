#!/bin/bash
#$ -N rename_needle
#$ -cwd
#$ -l h_rt=02:00:00
#$ -l h_vmem=2G
#$ -m bea
#$ -M sxxxxx@ed.ac.uk

#load reqired envs
. /etc/profile.d/modules.sh
module load anaconda
conda activate /exports/eddie/scratch/sxxxxxx/envs/needle

#dirs
INPUT_DIR="/exports/eddie/scratch/sxxxxxx/JCVI_needle/raw_outputs"
OUTPUT_DIR="/exports/eddie/scratch/sxxxxxx/JCVI_needle/raw_outputs_clean"

mkdir -p "$OUTPUT_DIR"

#remove .fasta from middle of file names
for filepath in "$INPUT_DIR"/*.needle; do
    filename=$(basename "$filepath")
    new_filename="${filename/.fasta/}"
    cp "$filepath" "$OUTPUT_DIR/$new_filename"
done

echo "clean files saved in $OUTPUT_DIR"

