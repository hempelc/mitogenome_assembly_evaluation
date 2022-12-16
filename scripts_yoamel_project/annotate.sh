#!/bin/bash
fa=$1
out=$2

MitoZ.simg annotate \
  	--genetic_code 5 \
  	--clade Arthropoda \
  	--outprefix ${out} \
  	--thread_number 32 \
  	--fastafile ${fa}

mv tmp ${out}_tmp
