#!/bin/bash

seed=/hdd1/chempel/bob_yoamel_midge_assembly_project/culicoides_biguttatus/assembly/C_biguttatus_COI_seed.fasta
threads=16

for i in /hdd1/chempel/bob_yoamel_midge_assembly_project/bwa_yoamel_trimmed_reads/PHRED*/C._biguttatus/*G0[13]*; do
  mkdir $(basename ${i})
  cd $(basename ${i})
  R1=${i}/*R1.fastq
  R2=${i}/*R2.fastq

  megahit -t ${threads} -1 ${R1} -2 ${R2} -o MEGAHIT/

  spades.py -t ${threads} -1 ${R1} -2 ${R2} -o SPADES/

  spades.py  -t ${threads} --rna -1 ${R1} -2 ${R2} -o RNASPADES/

  MitoZ.simg assemble \
  --genetic_code 5 \
  --clade Arthropoda \
  --outprefix MITOZ_ASSEMBLY \
  --thread_number ${threads} \
  --fastq1 ${R1} \
  --fastq2 ${R2} \
  --fastq_read_length 300 \
  --insert_size 250 \
  --run_mode 2 \
  --filter_taxa_method 1 \
  --requiring_taxa 'Arthropoda'
  mv MITOZ_ASSEMBLY.result/ MITOZ/
  mv tmp/ MITOZ/assembly_tmp/
  ### Rename output files
  for i in MITOZ/work71.*; do
  mv ${i} $(echo ${i} | sed 's/work71/mitoz/')
  done

  #MITObim
  mkdir MITObim
  cd MITObim
  interleave-reads.sh ${R1} ${R2} interleaved.fastq
  cp $(realpath ${seed}) .
  mv $(basename ${seed}) seed.fa
  sudo docker run -v $(pwd):/home/data chrishah/mitobim /bin/bash -c \
  "cd data; MITObim.pl -sample C_biguttatus -ref C_biguttatus_COI_seed -readpool interleaved.fastq --quick seed.fa -end 100 --clean"
  cd ..

  # NOVOPlasty
  mkdir NOVOPlasty
  cd NOVOPlasty
  NOVOPlasty_script.sh  ${R1} ${R2} ${seed} 300 c_biguttatus_novoplasty
  cd ..

  cd ..
done
