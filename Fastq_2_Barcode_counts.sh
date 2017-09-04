#!/bin/bash

# To run the file : In terminal :  bash Fastq_2_Barcode_counts.sh NameOf.fastq Prefix Barcode_length
# First argument is input file (fastq), second argument is output file root (prefix of your choice),
# third argument is length of labeling BC (usually 9 or 12)


# Code by Chris Fiore, former graduate student in Cohen Lab. Shared with permission.
# Contact hemangi@wustl.edu for any clarification.

# Takes one fastq file as input. Splits up replicates if any, and outputs one file per replicate. 
# Each replicate contains a list of barcodes and their read counts 
# Your reads have to be in this formate : ,,,,XXXXXX......YYYYYY,,,,,,,,,,,,  where:
# ,,,, : irrelevant sequence
# XXXXXX : P1 index, 1 index per sample or replicate
# ...... : one specific sequence between XXXXXX and YYYYYYYY, same for all samples or replicates
# YYYYYY : MPRA barcode

# !!!!! FILL IN HERE
MPBC=('GCTCGATC' 'TAGACTAT' 'CGCTACCCT' 'ATAGTGGACA' 'GTCAGTAGGTA')
BCNUM=(01 02 03 04 05) # Multiplex BCs used in the sample and numbers that refer to them

# MIDDLE is sequence between multiplex BC and labeling BC
MIDDLE='ATGC'

ARGS=("$@")

# Check for correct number of arguments
if [ "$#" -ne 3 ]; then
	echo "Usage: [input file] [output file root] [BC length]"
	exit 1
fi

BCLENGTH=${ARGS[2]}

# Pulls lines from fastq file that contain sequence and puts in a temporary file
TMPFILE="tmp"$(date +%s)
wdCount=$(echo $(sed '2q;d' ${ARGS[0]})| wc -c) 
wdCount=$((wdCount-1))
grep -e "[AGCTN]\{$wdCount,\}" ${ARGS[0]} > $TMPFILE

# Loops through each multiplex BC used in the sample
for k in $(seq 0 $(expr ${#MPBC[*]} - 1))
do
	echo "Processing BC "${BCNUM[$k]}
	CURRENTFILE=${ARGS[1]}'_'${BCNUM[$k]}
	
	# Pulls the labeling BC sequence from each line and outputs it, only if 
	# the sequence has the proper middle sequence and current multiplex BC
	sed -n 's/.*'${MPBC[$k]}$MIDDLE'\([ACGT]\{'$BCLENGTH'\}\).*/\1/p' $TMPFILE > $CURRENTFILE
	
	# Sorts the labeling BCs (necessary for uniq command) and then collapses
	# them by the unique BC sequence with counts of how many times each
	# labeling BC appears in the file
	sort $CURRENTFILE | uniq -c >$CURRENTFILE"_counts"
done

# Removes temporary file of just full sequences
rm $TMPFILE
