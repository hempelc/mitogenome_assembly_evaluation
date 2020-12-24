#!/bin/bash

# Version 0.1, made on 23 Dec 2020 by Chris Hempel (https://github.com/hempelc)

# A script to assemble mitogenomes using a variety of assemblers and to
# compare and evaluate the results

# Must have megahit, spades, idba-ud, Trinity, and idba-tran installed
# Must have mitoz downloaded as singularity file
# To download/install these programs automatically, run the script
# mitogenome_assembly_evaluation_installations.sh

cmd="$0 $@" # Make variable containing full used command to print command in logfile
usage="$(basename "$0") -1 <R1.fastq> -2 <R2.fastq> -l <length> -M </path/to/MitoZ.simg> [-t <n>]

Usage:
	-1  Reads1
	-2  Reads2
	-l  Read length
	-M  Path to MitoZ.simg singularity docker
	-h  Display this help and exit"

# Set default options:
threads='16'
start=$(date +%s)

# Define function to print steps with time
step_description_and_time () {
	echo -e "======== [$(date +%H:%M:%S)] ${1} [Runtime: $((($(date +%s)-$start)/3600))h $(((($(date +%s)-$start)%3600)/60))m] ========\n"
}

# Set specified options
while getopts ':1:2:l:h' opt; do
  case "${opt}" in
    1) R1="${OPTARG}" ;;
    2) R2="${OPTARG}" ;;
    l) length="${OPTARG}" ;;
		t) threads="${OPTARG}" ;;
		M) mitoz="${OPTARG}" ;;
		h) echo "${usage}"
       exit ;;
    :) printf "Option -$OPTARG requires an argument."
       echo -e "\n${usage}"
       exit ;;
    \?)printf "Invalid option: -$OPTARG"
       echo -e "\n${usage}"
       exit
  esac
done
shift $((OPTIND - 1))


# Check if required options are set
if [[  -z "${R1}" || -z "${R2}" || -z "${length}" || -z "${mitoz}"]]
then
   echo -e "\n-1, -2, -l, and -M must be set.\n"
   echo -e "${usage}\n\n"
   echo -e "Exiting script.\n"
   exit
fi

( # Bracket for log file

# Define starting time of script:


# Output specified options:
step_description_and_time "OPTIONS"

echo -e "Forward reads were defined as ${R1}.\n"
echo -e "Reverse reads were defined as ${R2}.\n"
echo -e "Read length was defined as ${length}.\n"
echo -e "Number of threads was set to ${threads}.\n"
echo -e "Script started with full command: $cmd\n"

# Make main output directory
mkdir mitogenome_assembly_evaluation
cd mitogenome_assembly_evaluation

# Running assemblers
## Running MEGAHIT
step_description_and_time "RUNNING MEGAHIT"
megahit -t ${threads} -1 ${R1} -2 ${R2} -o MEGAHIT/

## Running SPAdes ## TO DO: change so that started with python3
step_description_and_time "RUNNING SPADES"
spades.py -1 ${R1} -2 ${R2} -o SPADES/

## Running rnaSPAdes
step_description_and_time "RUNNING RNASPADES"
spades.py --rna -1 ${R1} -2 ${R2} -o RNASPADES/

## Running IDBA-UD
step_description_and_time "RUNNING IDBA-UD"
fq2fa --merge --filter ${R1} ${R2} idba_input.fa
idba_ud --num_threads ${threads} --pre_correction -r idba_input.fa -o IDBA_UD/
cp idba_input.fa IDBA_UD/

## Running IDBA-tran
step_description_and_time "RUNNING IDBA-tran"
idba_tran --num_threads ${threads} --pre_correction -l idba_input.fa -o IDBA_TRAN/
mv idba_input.fa IDBA_TRAN/

## Running Trinity
step_description_and_time "RUNNING TRINITY"
Trinity --seqType fq \
--max_memory $(echo $(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024 * 1024)-5)))G \
--left ${R1} --right ${R2} \
--CPU ${threads} --output TRINITY

## Running MitoZ
step_description_and_time "RUNNING MitoZ"
${mitoz} assemble \
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
#rm -r tmp

# Find mito contigs in assemblers that are not MitoZ
## Make list of files from assemblers (all but MitoZ)
assembly_list=(MEGAHIT/final.contigs.fa SPADES/scaffolds.fasta RNASPADES/scaffolds.fasta IDBA_UD/contig.fa IDBA_TRAN/contig.fa \
TRINITY/Trinity.fa)

## Run the MitoZ module findmitoscaf on all outputs
for i in ${assembly_list}; do
	${mitoz} findmitoscaf \
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

	${mitoz} annotate \
	--genetic_code 5 \
	--clade Arthropoda \
	--outprefix $(echo $(basename ${i%/*})_annotate) \
	--thread_number ${threads} \
	--fastq1 ${R1} \
	--fastq2 ${R2} \
	--fastafile $(echo $(basename ${i%/*}).results/$(basename ${i%/*}).mitogenome.fa)
	rm -r tmp
done

# Visualize seqs

#${mitoz} visualize --gb mitogenome.gb

) 2>&1 | tee mitogenome_assembly_evaluation_log.txt # Make logfile
