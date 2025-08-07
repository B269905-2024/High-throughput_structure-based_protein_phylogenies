#!/bin/bash
#script for splitting fasta file

#$ -N split_fats               
#$ -cwd                         
#$ -l h_rt=00:30:00             
#$ -l h_vmem=8G                 
#$ -m bea                       
#$ -M s2713107@ed.ac.uk         


INPUT_FASTA="JCVI-syn3A_noA.fasta"
OUTPUT_DIR="/exports/eddie/scratch/sxxxxxx/JCVI_needle/fasta_split"
mkdir -p "$OUTPUT_DIR"

awk -v out="$OUTPUT_DIR" '/^>/{if(f){close(f)}; f=out"/"substr($1,2)".fasta"} {print >> f}' "$INPUT_FASTA"

