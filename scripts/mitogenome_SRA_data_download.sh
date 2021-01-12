#!/bin/bash

# Version 0.1, made on 07 Jan 2021 by Chris Hempel (https://github.com/hempelc)

# A script to download SRA data to assemble mitogenomes

# Usage: [script_name] <SRA_list>

SRA_list=$1

while read SRA_number; do
  mkdir ${SRA_number}_reads
  fasterq-dump --split-3 --threads 32 --outdir ${SRA_number}_reads/ ${SRA_number}
done <${SRA_list}
