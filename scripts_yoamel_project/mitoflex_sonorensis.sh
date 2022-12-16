#!/bin/bash

base_dir=$(pwd)

for spec in F002 F004; do
  for score in 5 20; do
  R1=C-sonorensis_yoamel_${spec}_phred${score}_R1.fq
  R2=C-sonorensis_yoamel_${spec}_phred${score}_R2.fq

  cd PHRED${score}/C._sonorensis

 mkdir Mitoflex_${spec}/
 cd Mitoflex_${spec}/
echo ../${R1}
 MitoFlex.py assemble --insert-size 400 \
  --workname mitoflex \
  --fastq1 ../${R1} --fastq2 ../${R2}
 cd ..

 cd $base_dir

  done
done
