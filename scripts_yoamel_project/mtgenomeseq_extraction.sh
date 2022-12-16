#!/bin/bash
# Start in species dir

phred=$1

for i in *; do
  cd $i

  # MITObim
  cp MITObim*/*/*noIUPAC* ./seq.fa
  sed -i "s/>.*$/>${i}_PHRED${phred}_mitobim/g" seq.fa
  mv seq.fa mtgenomeseqs/mitobim.fa

  #SPADES
  head -n 1 SPADES*/scaffolds.fasta | sed 's/>//g' > tmp
  seqtk subseq SPADES*/scaffolds.fasta tmp > seq.fa
  rm tmp
  sed -i "s/>.*$/>${i}_PHRED${phred}_spades/g" seq.fa
  mv seq.fa mtgenomeseqs/spades.fa

  #RNASPADES
  head -n 1 RNASPADES*/transcripts.fasta | sed 's/>//g' > tmp
  seqtk subseq RNASPADES*/transcripts.fasta tmp > seq.fa
  rm tmp
  sed -i "s/>.*$/>${i}_PHRED${phred}_rnaspades/g" seq.fa
  mv seq.fa mtgenomeseqs/rnaspades.fa

  #NOVOPlasty
  cp NOVO*/*.fasta ./seq.fa
  sed -i "s/>.*$/>${i}_PHRED${phred}_novoplasty/g" seq.fa
  mv seq.fa mtgenomeseqs/novoplasty.fa

  #MitoFlex
  grep ">" Mitoflex*/mitoflex/mitoflex.result/scaf.fa | sed 's/len=//g' | sort -k4n \
  | tail -n 1 | sed 's/>//g' > tmp
  seqtk subseq Mitoflex*/mitoflex/mitoflex.result/scaf.fa tmp > seq.fa
  rm tmp
  sed -i "s/>.*$/>${i}_PHRED${phred}_mitoflex/g" seq.fa
  mv seq.fa mtgenomeseqs/mitoflex.fa

  #MEGAHIT
  grep ">" MEGAHIT*/final.contigs.fa | sed 's/len=//g' | sort -k4n \
  | tail -n 1 | sed 's/>//g' > tmp
  seqtk subseq MEGAHIT*/final.contigs.fa tmp > seq.fa
  rm tmp
  sed -i "s/>.*$/>${i}_PHRED${phred}_megahit/g" seq.fa
  mv seq.fa mtgenomeseqs/megahit.fa

  #MitoZ
  grep ">" MITOZ*/mitoz.mitogenome.fa | tail -n1 | sed 's/>//g' > tmp
  seqtk subseq MITOZ*/mitoz.mitogenome.fa tmp > seq.fa
  rm tmp
  sed -i "s/>.*$/>${i}_PHRED${phred}_mitoz/g" seq.fa
  mv seq.fa mtgenomeseqs/mitoz.fa


  cd ../
done
