#!/bin/bash
#$ -N needle_array
#$ -cwd
#$ -t 1-457
#$ -l h_rt=00:10:00
#$ -l h_vmem=4G
#$ -m bea
#$ -M sxxxxxx@ed.ac.uk

# Load and activate environment
. /etc/profile.d/modules.sh
module load anaconda
conda activate /exports/eddie/scratch/sxxxxx/envs/needle

# Define paths
FASTA_DIR="/exports/eddie/scratch/sxxxxx/JCVI_needle/fasta_split"
OUT_DIR="/exports/eddie/scratch/sxxxxx/JCVI_needle/raw_outputs_needle"
mkdir -p "$OUT_DIR"

# Get query file based on task ID
QUERY=$(ls $FASTA_DIR | sed -n "${SGE_TASK_ID}p")
QUERY_NAME="${QUERY%.fasta}"

# Align this query to every other sequence
for TARGET in $FASTA_DIR/*.fasta; do
    TARGET_BASENAME="$(basename "$TARGET" .fasta)"
    OUTFILE="${OUT_DIR}/${QUERY_NAME}__${TARGET_BASENAME}.needle"
    if [[ ! -f "$OUTFILE" ]]; then
        needle -asequence "$FASTA_DIR/$QUERY" \
               -bsequence "$TARGET" \
               -gapopen 10 -gapextend 0.5 \
               -outfile "$OUTFILE" -auto
    fi
done

