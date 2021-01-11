#!/bin/bash

# Version 0.1, made on 07 Jan 2021 by Chris Hempel (https://github.com/hempelc)

# A script to assemble mitogenomes using MitoZ

# Must have mitoz downloaded as singularity file and in PATH
# To download/install this program and add it to the PATH automatically,
# run the script mitogenome_assembly_evaluation_installations.sh

R1=$1
R2=$2
length=$3
threads=$4

# Define function to print steps with time
step_description_and_time () {
	echo -e "======== [$(date +%H:%M:%S)] ${1} [Runtime: $((($(date +%s)-$start)/3600))h $(((($(date +%s)-$start)%3600)/60))m] ========\n"
}

## Running MEGAHIT
step_description_and_time "RUNNING MEGAHIT"
megahit -t ${threads} -1 ${R1} -2 ${R2} -o MEGAHIT/

## Running MitoZ
step_description_and_time "RUNNING MitoZ"
./MitoZ.simg assemble \
--genetic_code 5 \
--clade Arthropoda \
--outprefix MitoZ \
--thread_number ${threads} \
--fastq1 ${R1} \
--fastq2 ${R2} \
--fastq_read_length ${length} \
--insert_size 250 \
--run_mode 2 \
--filter_taxa_method 1 \
--requiring_taxa 'Arthropoda'

assembly_list=(MEGAHIT/final.contigs.fa)

## Run the MitoZ module findmitoscaf on all outputs
for i in ${assembly_list}; do
	./MitoZ.simg findmitoscaf \
	--genetic_code 5 \
	--clade Arthropoda \
	--outprefix $(echo $(basename ${i%/*})_findmitoscaf) \
	--thread_number ${threads} \
	--fastq1 ${R1} \
	--fastq2 ${R2} \
	--fastq_read_length ${length} \
	--fastafile $i
	rm -r tmp

	# Annotate seqs

./MitoZ.simg annotate \
	--genetic_code 5 \
	--clade Arthropoda \
	--outprefix $(echo $(basename ${i%/*})_annotate) \
	--thread_number ${threads} \
	--fastq1 ${R1} \
	--fastq2 ${R2} \
	--fastafile $(echo $(basename ${i%/*}).results/$(basename ${i%/*}).mitogenome.fa)
	rm -r tmp
done
