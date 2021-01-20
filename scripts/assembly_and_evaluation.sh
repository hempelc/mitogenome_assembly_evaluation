#!/bin/bash

# Version 0.1, made on 07 Jan 2021 by Chris Hempel (https://github.com/hempelc)

# A script to assemble mitogenomes using MitoZ

# Must have MEGAHIT, SPAdes, IDBA-UD, Trinity, and IDBA-tran installed and in PATH
# Must have Mitoz downloaded as singularity file and in PATH
# To download/install all programs and add them to the PATH automatically,
# run the following script as follows: source mitogenome_assembly_evaluation_installations.sh

cmd="$0 $@" # Make variable containing full used command to print command in logfile
usage="$(basename "$0") -1 <R1.fastq> -2 <R2.fastq> -l <length> -c <clade> [-t <n> -ae]

Usage:
	-1  Reads1
	-2  Reads2
	-l  Read length (needed for Mitoz)
  -c  Clade of species ('Arthropoda' or 'Chordata')
  -a  Assemblies only
  -e  Evaluation only
  -t  Threads (default: 16)
	-h  Display this help and exit"

# Set default options:
threads='16'
asmbl_flag=true
eval_flag=true

# Set specified options
while getopts ':1:2:l:c:a:e:t:h' opt; do
  case "${opt}" in
    1) R1=$(realpath "${OPTARG}") ;;
    2) R2=$(realpath "${OPTARG}") ;;
    l) length="${OPTARG}" ;;
    c) clade="${OPTARG}" ;;
    a) asmbl_flag=false ;;
    e) eval_flag=false ;;
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
if [[ -z "${R1}" || -z "${R2}" || -z "${length}" || -z "${clade}" ]]; then
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
echo -e "Clade was set to ${clade} with genetic code ${genetic_code}.\n".
echo -e "Number of threads was set to ${threads}.\n"
echo -e "Script started with full command: ${cmd}\n"

# Make output dir
mkdir -p mitogenome_assembly_evaluation_results/
cd mitogenome_assembly_evaluation_results/


if [[ "${asmbl_flag}" == "true" ]]; then
  # Running assemblers
  mkdir -p assemblies/

  ## Running MEGAHIT
  step_description_and_time "Running MEGAHIT"
  megahit -t ${threads} -1 ${R1} -2 ${R2} -o MEGAHIT/
  mv MEGAHIT/final.contigs.fa assemblies/
  rm -r MEGAHIT/ # remove to save space

  ## Running SPAdes
  step_description_and_time "Running SPADES"
  spades.py -t ${threads} -1 ${R1} -2 ${R2} -o SPADES/
  mv SPADES/scaffolds.fasta assemblies/
  rm -r SPADES/ # remove to save space

  ## Running rnaSPAdes
  step_description_and_time "Running RNASPADES"
  spades.py  -t ${threads} --rna -1 ${R1} -2 ${R2} -o RNASPADES/
  mv RNASPADES/transcripts.fasta assemblies/
  rm -r RNASPADES/ # remove to save space

  ## Running IDBA-UD
  step_description_and_time "Running IDBA-UD"
  fq2fa --merge --filter ${R1} ${R2} idba_input.fa
  idba_ud --num_threads ${threads} --pre_correction -r idba_input.fa -o IDBA_UD/
  cp idba_input.fa IDBA_UD/
  mv IDBA_UD/contig.fa assemblies/
  rm -r IDBA_UD/ # remove to save space

  ## Running IDBA-tran
  step_description_and_time "Running IDBA-tran"
  idba_tran --num_threads ${threads} --pre_correction -l idba_input.fa -o IDBA_TRAN/
  mv idba_input.fa IDBA_TRAN/
  mv IDBA_TRAN/contig.fa assemblies/
  rm -r IDBA_TRAN/ # remove to save space

  ## Running Trinity
  step_description_and_time "Running TRINITY"
  Trinity --seqType fq \
  --max_memory $(echo $(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024 * 1024)-5)))G \
  --left ${R1} --right ${R2} \
  --CPU ${threads} --output TRINITY
  mv TRINITY/Trinity.fa assemblies/
  rm -r TRINITY/ # remove to save space

  ## Running MitoZ assembly module
  step_description_and_time "Running MitoZ assembly module"
  MitoZ.simg assemble \
  --genetic_code 5 \
  --clade Arthropoda \
  --outprefix MITOZ_ASSEMBLY \
  --thread_number ${threads} \
  --fastq1 ${R1} \
  --fastq2 ${R2} \
  --fastq_read_length ${length} \
  --insert_size 250 \
  --run_mode 2 \
  --filter_taxa_method 1 \
  --requiring_taxa 'Arthropoda'
  mv tmp/ MITOZ_ASSEMBLY.result/assembly_tmp/
  ### Rename output files
  for i in MITOZ_ASSEMBLY.result/work71.*; do
    mv ${i} $(echo ${i} | sed 's/work71/mitoz/')
  done
mv MITOZ_ASSEMBLY.result/mitoz.mitogenome.fa assemblies/
rm -r MITOZ_ASSEMBLY.result/ # remove to save space
fi

if [[ "${eval_flag}" == "true" ]]; then
  # Make list of files from assemblers (all but MitoZ)
  assembly_list=(MEGAHIT/final.contigs.fa SPADES/scaffolds.fasta RNASPADES/transcripts.fasta IDBA_UD/contig.fa IDBA_TRAN/contig.fa \
  TRINITY/Trinity.fa MITOZ_ASSEMBLY.result/mitoz.mitogenome.fa)

  # Running the MitoZ modules findmitoscaf and annotate on all assembly outputs
  mkdir -p evaluation/
  mkdir -p evaluation/circos/
  mkdir -p evaluation/summaries/

  for i in "${assembly_list[@]}"; do
    ## Make variables for easier file handling and change into respective dir
    assembler=$(dirname ${i})
    assembly_result=$(realpath assemblies/$(basename ${i}))
    cd evaluation/

    ## Make fasta headers short, otherwise errors
    if [[ ${assembler} == "TRINITY" ]]; then
      echo "Shortening ${assembler} fasta head names"
      awk '{for(x=1;x<=NF;x++)if($x~/TRINITY/){sub(/TRINITY/,++i)}}1' \
      ${assembly_result} | sed 's/_[^ ]*//g' \
      > $(dirname ${assembly_result})/Trinity_short.fasta
      assembly_result="$(dirname ${assembly_result})/Trinity_short.fasta"
    elif [[ ${assembler} == "SPADES" ]]; then
      echo "Shortening ${assembler} fasta head names"
      sed 's/_length_.*$//g' ${assembly_result} \
      > $(dirname ${assembly_result})/scaffolds_short.fasta
      assembly_result="$(dirname ${assembly_result})/scaffolds_short.fasta"
    elif [[ ${assembler} == "RNASPADES" ]]; then
      echo "Shortening ${assembler} fasta head names"
      sed 's/_length_.*$//g' ${assembly_result} \
      > $(dirname ${assembly_result})/transcripts_short.fasta
      assembly_result="$(dirname ${assembly_result})/transcripts_short.fasta"
    fi

    ## Findmitoscaf module
    step_description_and_time "Running MitoZ findmitoscaf module on ${assembler} output"
  	MitoZ.simg findmitoscaf \
  	--genetic_code ${genetic_code} \
  	--clade ${clade} \
  	--outprefix ${assembler}_findmitoscaf \
  	--thread_number ${threads} \
  	--fastq1 ${R1} \
  	--fastq2 ${R2} \
  	--fastq_read_length ${length} \
  	--fastafile ${assembly_result}
    mv tmp/ ${assembler}_findmitoscaf.result/tmp_findmitoscaf/

  	## Annotate module
    step_description_and_time "Running MitoZ annotate module on ${assembler} output"
    MitoZ.simg annotate \
  	--genetic_code ${genetic_code} \
  	--clade ${clade} \
  	--outprefix ${assembler}_annotate \
  	--thread_number ${threads} \
  	--fastq1 ${R1} \
  	--fastq2 ${R2} \
  	--fastafile ${assembler}_findmitoscaf.result/${assembler}_findmitoscaf.mitogenome.fa
  	mv tmp/ ${assembler}_annotate.result/tmp_annotate/
    for i in circos.jpg circos.svg summary.txt; do
      mv ${assembler}_annotate.result/${i} ${assembler}_annotate.result/${assembler}_${i}
    done
    cp ${assembler}_annotate.result/*circos* circos/
    cp ${assembler}_annotate.result/*summary.txt summaries/
    rm -r ${assembler}_*.result/
    cd ..
  done
fi

cd ..

) 2>&1 | tee mitogenome_assembly_log.txt # Make logfile
mv mitogenome_assembly_log.txt mitogenome_assembly_results/
