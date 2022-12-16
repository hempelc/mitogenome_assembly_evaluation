#!/bin/bash

base_dir=$(pwd)

for spec in G02 G04; do
  for score in 5 20; do
  R1=C-biguttatus_yoamel_${spec}_phred${score}_R1.fq
  R2=C-biguttatus_yoamel_${spec}_phred${score}_R2.fq

 cd PHRED${score}/C._biguttatus

 mkdir Mitoflex_${spec}/
 cd Mitoflex_${spec}/
 MitoFlex.py assemble --insert-size 400 \
  --workname mitoflex \
  --fastq1 ../${R1} --fastq2 ../${R2}
 cd ..

 cd $base_dir

  done
done
