#!/bin/bash

# Version 0.1, made on 07 Jan 2021 by Chris Hempel (https://github.com/hempelc)

# A script to download SRA data from al list to be used for mitogenome assembly

# Must have sra-toolkit installed (including fasterq-dump)

usage="$(basename "$0") -l <list.txt> [-t <n>]

Usage:
	-l  File containing list of SRA numbers to download. Note: last line of list
      must be empty!
  -t  Threads (default:16)
	-h  Display this help and exit"

# Set default options:
threads='16'

# Set specified options
while getopts ':l:t:h' opt; do
  case "${opt}" in
    l) SRA_list="${OPTARG}" ;;
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
if [[  -z "${SRA_list}" ]]
then
   echo -e "\n -l must be set.\n"
   echo -e "${usage}\n\n"
   echo -e "Exiting script.\n"
   exit
fi

while read SRA_number; do
	echo "Downloading ${SRA_number}..."
  mkdir ${SRA_number}_reads
  fasterq-dump --split-3 --threads ${threads} --outdir ${SRA_number}_reads/ \
  ${SRA_number}
done <${SRA_list}
