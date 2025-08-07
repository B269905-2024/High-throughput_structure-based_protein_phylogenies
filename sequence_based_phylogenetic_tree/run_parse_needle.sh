#!/bin/bash
#$ -N parse_needle
#$ -cwd
#$ -l h_rt=01:00:00
#$ -l h_vmem=4G
#$ -m bea
#$ -M sxxxxxx@ed.ac.uk

. /etc/profile.d/modules.sh
module load anaconda
conda activate /exports/eddie/scratch/s2713107/envs/needle

python3 parse_needle_outputs.py

