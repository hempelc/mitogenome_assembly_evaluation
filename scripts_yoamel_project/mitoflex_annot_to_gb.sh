#!/bin/zsh

cds=$1
rna=$2
out=$3

echo FEATURES > $out

grep '>' $cds | sed 's/>//g' | sed 's/gene=//g' \
  | sed 's/start=//g' | sed 's/end=//g' | sed 's/from=.* strand=//g' \
  | awk '{ print $1 " " $3 " " $4 " " $2 " " $5}' > out_tmp.txt
grep '>' $rna | sed 's/>//g' | sed 's/gene=//g' \
  | sed 's/start=//g' | sed 's/end=//g' \
  | awk '{ print $1 " " $3 " " $4 " " $2}' >> out_tmp.txt

while read line; do
  start=$(echo $line | cut -f 2 -d ' ')
  end=$(echo $line | cut -f 3 -d ' ')
  gen=$(echo $line | cut -f 4 -d ' ')
  if [[ ${gen:0:3} == 'trn' ]]; then
    name='tRNA'
  elif [[ ${gen:0:3} == 'rrn' ]]; then
    name='rRNA'
  else
    name='CDS'
  fi
  echo -e "\t${name}\t${start}..${end}\n\\t\t/gene=${gen}" >> $out; done < out_tmp.txt

echo ORIGIN >>$out

rm out_tmp.txt

