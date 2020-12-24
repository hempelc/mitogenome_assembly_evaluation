#!/bin/bash

# Version 0.1, made on 23 Dec 2020 by Chris Hempel (https://github.com/hempelc)

# A script to install DNA/RNA assemblers, enabling to assemble mitogenomes
# using a variety of assemblers and to compare and evaluate the results

# Installing dependencies
sudo apt-get update && sudo apt-get install -y build-essential uuid-dev \
libgpgme-dev squashfs-tools libseccomp-dev wget pkg-config git cryptsetup-bin \
libssl-dev libz-dev unzip

# Making programs dir
mkdir /home/ubuntu/programs/
cd /home/ubuntu/programs/

# Download pre-compiled SPAdes binaries:
wget https://cab.spbu.ru/files/release3.14.1/SPAdes-3.14.1-Linux.tar.gz
tar -zxf SPAdes-3.14.1-Linux.tar.gz
sudo rm SPAdes-3.14.1-Linux.tar.gz
for i in SPAdes-3.14.1-Linux/bin/*.py; do
	sed -i 's/\#\!\/usr\/bin\/env python/\#\!\/usr\/bin\/env python3/g' ${i}
done

# Download pre-compiled MEGAHIT binaries:
wget https://github.com/voutcn/megahit/releases/download/v1.2.9/MEGAHIT-1.2.9-Linux-x86_64-static.tar.gz
tar -zxf MEGAHIT-1.2.9-Linux-x86_64-static.tar.gz
sudo rm MEGAHIT-1.2.9-Linux-x86_64-static.tar.gz
sed -i 's/\#\!\/usr\/bin\/env python/\#\!\/usr\/bin\/env python3/g' \
MEGAHIT-1.2.9-Linux-x86_64-static/bin/megahit

# Download and install IDBA-UD/tran:
wget https://github.com/loneknightpy/idba/releases/download/1.1.3/idba-1.1.3.tar.gz
tar -zxf idba-1.1.3.tar.gz
sudo rm idba-1.1.3.tar.gz
sed -i 's/kMaxShortSequence = 128/kMaxShortSequence = 256/g' idba-1.1.3/src/sequence/short_sequence.h
cd idba-1.1.3
./configure && make
cd ..

# Download and install cmake, bowtie2, jellyfish, and salmon (needed for Trinity):
wget https://github.com/Kitware/CMake/releases/download/v3.19.2/cmake-3.19.2.tar.gz
tar -zxf cmake-3.19.2.tar.gz
sudo rm cmake-3.19.2.tar.gz
cd cmake-3.19.2
./bootstrap && make && sudo make install
cd ..
sudo rm -r cmake-3.19.2/
wget https://github.com/BenLangmead/bowtie2/releases/download/v2.4.2/bowtie2-2.4.2-linux-x86_64.zip
unzip bowtie2-2.4.2-linux-x86_64.zip
rm bowtie2-2.4.2-linux-x86_64.zip
wget https://github.com/gmarcais/Jellyfish/releases/download/v2.3.0/jellyfish-linux
chmod +x jellyfish-linux
wget https://github.com/COMBINE-lab/salmon/releases/download/v1.4.0/salmon-1.4.0_linux_x86_64.tar.gz
tar -zxf salmon-1.4.0_linux_x86_64.tar.gz
rm salmon-1.4.0_linux_x86_64.tar.gz

#Download and install Trinity:
wget https://github.com/trinityrnaseq/trinityrnaseq/releases/download/v2.11.0/trinityrnaseq-v2.11.0.FULL.tar.gz
tar -zxf trinityrnaseq-v2.11.0.FULL.tar.gz
sudo rm trinityrnaseq-v2.11.0.FULL.tar.gz
cd trinityrnaseq-v2.11.0
make
cd ..

# Download and install Go and Singularity (Needed for MitoZ):
wget https://golang.org/dl/go1.15.6.linux-amd64.tar.gz
sudo tar -C /usr/local -zxf go1.15.6.linux-amd64.tar.gz
sudo rm go1.15.6.linux-amd64.tar.gz
echo -e '\n# Manually added  paths.\n\nexport PATH=/usr/local/go/bin:$PATH' \
>> ~/.bashrc && source ~/.bashrc
wget https://github.com/hpcng/singularity/releases/download/v3.7.0/singularity-3.7.0.tar.gz
tar -zxf singularity-3.7.0.tar.gz
sudo rm singularity-3.7.0.tar.gz
cd singularity
./mconfig && make -C builddir \
&& sudo make -C builddir install
cd ..
sudo rm -r singularity

# Download Singularity image of MitoZ:
## Note: is not installed directly but just downloaded as a singularity image
## and run directly from the image
singularity pull  --name MitoZ.simg shub://linzhi2013/MitoZ:v2.3

# Move back to dir where script was started:
cd ..

# Add downloaded/installed programs to path:
for program in /home/ubuntu/programs/ \
/home/ubuntu/programs/MEGAHIT-1.2.9-Linux-x86_64-static/bin/ \
/home/ubuntu/programs/SPAdes-3.14.1-Linux/bin/ \
/home/ubuntu/programs/idba-1.1.3/bin/ \
/home/ubuntu/programs/salmon-latest_linux_x86_64/bin/ \
/home/ubuntu/programs/bowtie2-2.4.2-linux-x86_64; do
	echo -e "export PATH=${program}:"'$PATH' >> ~/.bashrc
done
echo -e '\n# Manually added  aliases.\n\nalias python=python3' >> ~/.bashrc
source ~/.bashrc
