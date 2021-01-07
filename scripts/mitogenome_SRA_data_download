#!/bin/bash

# Version 0.1, made on 07 Jan 2021 by Chris Hempel (https://github.com/hempelc)

# A script to download SRA data to assemble mitogenomes

# Usage: [script_name] <SRA_number_file>

# SRA_number_file=$1

# TO DO: for loop over lines in SRA_number_file
# SRA_number=XXX

# For now: testing only one SRA number
SRA_number="SRR1145747"

fastq-dump --split-3 ${SRA_number}
