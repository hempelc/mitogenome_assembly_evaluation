#!/bin/bash

seed=/hdd1/chempel/bob_yoamel_midge_assembly_project/culicoides_sonorensis/assembly/C_sonorensis_COI_seed.fasta
threads=16
base_dir=$(pwd)

for spec in F002 F004; do
  for score in 5 20; do
  R1=C-sonorensis_yoamel_${spec}_phred${score}_R1.fq
  R2=C-sonorensis_yoamel_${spec}_phred${score}_R2.fq

  cd PHRED${score}/C._sonorensis

  megahit -t ${threads} -1 ${R1} -2 ${R2} -o MEGAHIT_${spec}/

  spades.py -t ${threads} -1 ${R1} -2 ${R2} -o SPADES_${spec}/

  spades.py  -t ${threads} --rna -1 ${R1} -2 ${R2} -o RNASPADES_${spec}/

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
  mv MITOZ_ASSEMBLY.result/ MITOZ_${spec}/
  mv tmp/ MITOZ_${spec}/assembly_tmp/
  ### Rename output files
  for i in MITOZ_${spec}/work71.*; do
  mv ${i} $(echo ${i} | sed 's/work71/mitoz/')
  done

  #MITObim
  mkdir MITObim_${spec}
  cd MITObim_${spec}
  interleave-reads.sh ../${R1} ../${R2} interleaved.fastq
  cp $(realpath ${seed}) .
  mv $(basename ${seed}) seed.fa
  sudo docker run -v $(pwd):/home/data chrishah/mitobim /bin/bash -c \
  "cd data; MITObim.pl -sample C_biguttatus -ref C_biguttatus_COI_seed -readpool interleaved.fastq --quick seed.fa -end 100 --clean"
  cd ..

  # NOVOPlasty
  mkdir NOVOPlasty_${spec}
  cd NOVOPlasty_${spec}
  NOVOPlasty_script.sh ../${R1} ../${R2} ${seed} 250 c_biguttatus_novoplasty
  cd ..

  cd $base_dir

  done
done
