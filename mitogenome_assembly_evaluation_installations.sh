#!/bin/bash

# Version 0.1, made on 23 Dec 2020 by Chris Hempel (https://github.com/hempelc)

# A script to install DNA/RNA assemblers to eventually assemble mitogenomes
# using a variety of assemblers and to compare and evaluate the results

mkdir /home/ubuntu/programs/
cd /home/ubuntu/programs/

# Download pre-compiled SPAdes:
wget https://cab.spbu.ru/files/release3.14.1/SPAdes-3.14.1-Linux.tar.gz
tar -zvxf SPAdes-3.14.1-Linux.tar.gz
sudo rm SPAdes-3.14.1-Linux.tar.gz

# Download pre-compiled MEGAHIT:
wget https://github.com/voutcn/megahit/releases/download/v1.2.9/MEGAHIT-1.2.9-Linux-x86_64-static.tar.gz
tar -zvxf MEGAHIT-1.2.9-Linux-x86_64-static.tar.gz
sudo rm MEGAHIT-1.2.9-Linux-x86_64-static.tar.gz

# Download and install IDBA-UD/tran:
wget https://github.com/loneknightpy/idba/releases/download/1.1.3/idba-1.1.3.tar.gz
tar -xzvf idba-1.1.3.tar.gz
sudo rm idba-1.1.3.tar.gz
sed -i 's/kMaxShortSequence = 128/kMaxShortSequence = 256/g' idba-1.1.3/src/sequence/short_sequence.h
cd idba-1.1.3 $$ ./configure && make && cd ..

# Download pre-compiled Trinity:
wget https://github.com/trinityrnaseq/trinityrnaseq/releases/download/v2.11.0/trinityrnaseq-v2.11.0.FULL.tar.gz
tar -zvxf trinityrnaseq-v2.11.0.FULL.tar.gz
sudo rm trinityrnaseq-v2.11.0.FULL.tar.gz
cd trinityrnaseq-v2.11.0 && make && cd ..

# Download and install Go and Singularity (Needed for MitoZ):
sudo apt-get update && sudo apt-get install -y libssl-dev uuid-dev \
libgpgme11-dev libseccomp-dev pkg-config && sudo apt -y autoremove
wget https://golang.org/dl/go1.15.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzvf go1.15.6.linux-amd64.tar.gz
sudo rm go1.15.6.linux-amd64.tar.gz
echo -e '# Manually added  paths.\n\nexport PATH=/usr/local/go/bin:$PATH' \
>> ~/.bashrc && source ~/.bashrc
wget https://github.com/hpcng/singularity/releases/download/v3.7.0/singularity-3.7.0.tar.gz
tar -zvxf singularity-3.7.0.tar.gz
sudo rm singularity-3.7.0.tar.gz
cd singularity && ./mconfig && make -C builddir \
&& sudo make -C builddir install && cd ..
sudo rm -r singularity

# Download Singularity image of MitoZ:
## Note: is not installed directly but just downloaded as a singularity image
## and run directly from the image
singularity pull  --name MitoZ.simg shub://linzhi2013/MitoZ:v2.3

# Move back to dir where script was started:
cd cd ..

# Add downloaded/installed programs to path:
for program in /home/ubuntu/programs/MEGAHIT-1.2.9-Linux-x86_64-static/bin/ \
/home/ubuntu/programs/SPAdes-3.14.1-Linux/bin/ \
/home/ubuntu/programs/idba-1.1.3/bin/ /home/ubuntu/programs/; do
	echo -e "export PATH=${program}:$PATH" >> ~/.bashrc
done && source ~/.bashrc
