#!/bin/bash

# Version 0.1, made on 07 Jan 2021 by Chris Hempel (https://github.com/hempelc)

# A script to assemble mitogenomes using MitoZ

# Must have MEGAHIT, SPAdes, IDBA-UD, Trinity, and IDBA-tran installed and in PATH
# Must have Mitoz downloaded as singularity file and in PATH
# To download/install all programs and add them to the PATH automatically,
# run the following script as follows: source mitogenome_assembly_evaluation_installations.sh

cmd="$0 $@" # Make variable containing full used command to print command in logfile
usage="$(basename "$0") -1 <R1.fastq> -2 <R2.fastq> -l <length> -c <clade> [-t <n>]

Usage:
	-1  Reads1
	-2  Reads2
	-l  Read length (needed for Mitoz)
  -c  Clade of species ('Arthropoda' or 'Chordata')
  -t  Threads (default: 16)
	-h  Display this help and exit"

# Set default options:
threads='16'

# Set specified options
while getopts ':1:2:l:c:t:h' opt; do
  case "${opt}" in
    1) R1="${OPTARG}" ;;
    2) R2="${OPTARG}" ;;
    l) length="${OPTARG}" ;;
    c) clade="${OPTARG}" ;;
    t) threads="${OPTARG}" ;;
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
if [[  -z "${R1}" || -z "${R2}" || -z "${length}" || -z "${clade}"]]
then
   echo -e "\n-1, -2, -l, and -c must be set.\n"
   echo -e "${usage}\n\n"
   echo -e "Exiting script.\n"
   exit
fi

if [[ ${clade} != 'Arthropoda' && ${clade} != 'Chordata' ]]; then
  echo -e "Invalid option for -c, must be set to either 'Arthropoda' or 'Chordata'\n"
  echo -e "$usage\n\n"
  echo -e "Exiting script\n"
  exit
fi

## Set genetic code based on clade
if [[ ${clade} == 'Arthropoda' ]]; then
  genetic_code='5'
else
  genetic_code='2'
fi

# Define function to print steps with time
start=$(date +%s)
step_description_and_time () {
	echo -e "\n======== [$(date +%H:%M:%S)] ${1} [Runtime: $((($(date +%s)-$start)/3600))h $(((($(date +%s)-$start)%3600)/60))m] ========\n" #" adding outcommented quote here to fix bug in colouring scheme of personal text editor
}

( # Bracket for log file


# Output specified options:
step_description_and_time "OPTIONS"

echo -e "Forward reads were defined as ${R1}.\n"
echo -e "Reverse reads were defined as ${R2}.\n"
echo -e "Read length was defined as ${length}.\n"
echo -e "Number of threads was set to ${threads}.\n"
echo -e "Number of threads was set to ${threads}.\n"
echo -e "Script started with full command: ${cmd}\n"

# Make output dir
mkdir -p mitogenome_assembly_results/
cd mitogenome_assembly_results/

# Running assemblers

## Running MEGAHIT
step_description_and_time "Running MEGAHIT"
megahit -t ${threads} -1 ../${R1} -2 ../${R2} -o MEGAHIT/

## Running SPAdes
step_description_and_time "Running SPADES"
spades.py -t ${threads} -1 ../${R1} -2 ../${R2} -o SPADES/

## Running rnaSPAdes
step_description_and_time "Running RNASPADES"
spades.py  -t ${threads} --rna -1 ../${R1} -2 ../${R2} -o RNASPADES/

## Running IDBA-UD
step_description_and_time "Running IDBA-UD"
fq2fa --merge --filter ../${R1} ../${R2} idba_input.fa
idba_ud --num_threads ${threads} --pre_correction -r idba_input.fa -o IDBA_UD/
cp idba_input.fa IDBA_UD/

## Running IDBA-tran
step_description_and_time "Running IDBA-tran"
idba_tran --num_threads ${threads} --pre_correction -l idba_input.fa -o IDBA_TRAN/
mv idba_input.fa IDBA_TRAN/

## Running Trinity
step_description_and_time "Running TRINITY"
Trinity --seqType fq \
--max_memory $(echo $(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024 * 1024)-5)))G \
--left ../${R1} --right ../${R2} \
--CPU ${threads} --output TRINITY

## Running MitoZ assembly module
step_description_and_time "Running MitoZ assembly module"
MitoZ.simg assemble \
--genetic_code 5 \
--clade Arthropoda \
--outprefix MITOZ_ASSEMBLY \
--thread_number ${threads} \
--fastq1 ../${R1} \
--fastq2 ../${R2} \
--fastq_read_length ${length} \
--insert_size 250 \
--run_mode 2 \
--filter_taxa_method 1 \
--requiring_taxa 'Arthropoda'
mv tmp/ tmp_assembly/
mv tmp_assembly/ MITOZ_ASSEMBLY.result/
### Rename output files
for i in MITOZ_ASSEMBLY.result/work71.*; do
  mv ${i} $(echo ${i} | sed 's/work71/mitoz/')
done

# Make list of files from assemblers (all but MitoZ)
assembly_list=(MEGAHIT/final.contigs.fa SPADES/scaffolds.fasta RNASPADES/scaffolds.fasta IDBA_UD/contig.fa IDBA_TRAN/contig.fa \
TRINITY/Trinity.fa MITOZ_ASSEMBLY.result/mitoz.mitogenome.fa)

# Running the MitoZ modules findmitoscaf and annotate on all assembly outputs
for i in ${assembly_list}; do
  ## Make variables for easier file handling and change into respective dir
  assembler=$(dirname ${i})
  assembly_result=$(basename ${i})
  cd ${assembler}

  ## Findmitoscaf module
  step_description_and_time "Running MitoZ findmitoscaf module on ${assembler} output"
	MitoZ.simg findmitoscaf \
	--genetic_code ${genetic_code} \
	--clade ${clade} \
	--outprefix ${assembler}_findmitoscaf \
	--thread_number ${threads} \
	--fastq1 ../${R1} \
	--fastq2 ../${R2} \
	--fastq_read_length ${length} \
	--fastafile ${assembly_result}
  mv tmp/ tmp_finsmitoscaf/
  mv tmp_finsmitoscaf/ ${assembler}_findmitoscaf.result

	## Annotate module
  step_description_and_time "Running MitoZ annotate module on ${assembler} output"
  MitoZ.simg annotate \
	--genetic_code ${genetic_code} \
	--clade ${clade} \
	--outprefix ${assembler}_annotate \
	--thread_number ${threads} \
	--fastq1 ../${R1} \
	--fastq2 ../${R2} \
	--fastafile ${assembler}_findmitoscaf.result/${assembler}_findmitoscaf.mitogenome.fa
	mv tmp/ tmp_annotate/
  mv tmp_annotate/ ${assembler}_annotate.result
  cd ..
done

) 2>&1 | tee mitogenome_assembly_log.txt # Make logfile
mv mitogenome_assembly_log.txt mitogenome_assembly_results/
