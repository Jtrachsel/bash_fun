#!/bin/bash

QC_stats() {
FASTA=$1
assembly="${FASTA%.f*}";
tot_len=$(grep -v ">" $FASTA | wc | awk '{print $3-$1}');
num_contigs=$(grep ">" $FASTA | wc -l);
printf '%s\t%s\t%s\n' $assembly $tot_len $num_contigs 
}

export -f QC_stats

#parallel QC_stats {} ::: *fasta > assembly_QC.tsv


rename_contigs() {
        FILE=$1
        BASE=$2
        awk -v awkv="$BASE" '/^>/{print ">"awkv"_"++i;next}{print}' "$FILE" > "$BASE"_rename.fasta
        rm $FILE
        mv "$BASE"_rename.fasta $FILE
}
export -f rename_contigs

# to execute in parallel
#parallel rename_contigs {} {.} ::: *fasta

# or if too many fastas for wildcards...
#find . -name "*fasta" | parallel rename_contigs {} {/.}


### GET SALMONELLA SEROTYPE WITH SEQSERO2
# parallel 'SeqSero2_package.py  -i {} -t 4 -c -m k > {.}.sero' ::: *fasta
# this is to scrape prediction into tab delimited format

getSalSero(){
FILE=$1
RESULT=$2

GENOME=$(cat $FILE | grep 'Input' |awk '{print $3}')
SERO=$(cat $FILE | grep 'serotype' | awk '{print $3" "$4}')

printf '%s\t%s%s\n' $GENOME $SERO > $RESULT

}

export -f getSalSero

#parallel getSalSero {} {.}.tmp ::: *.sero


#cat *tmp > ALL_SERO.tsv

# for only outputting verified I4512i- genomes
#awk '{if ($2 == "I4,[5],12:i:-") print $1}' ALL_SERO.tsv

# outputs the lengths of all contigs in an assembly, useful for 
# identifying blast hits that abut contig ends
getfastalens() {
        FILE=$1
        BASE=$2
        bioawk -c fastx '{ print $name, length($seq) }' < $FILE > "$BASE".lengths
}
export -f getfastalens

#parallel getfastalens {} {.} ::: *.fasta


# outputs lengths of each read in a fastq
get_fastq_lens(){
	awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' $1

}

#remove guided assembly contigs from path detect db assems
# needs java and bbtools

remove_guided_contigs(){

     BASENAME="${1%.fna}"
     cat $1 |grep '>'|grep 'guided' |sed 's/>//' > "${BASENAME}".badnames
     filterbyname.sh in=$1 names="${BASENAME}".badnames out="$BASENAME"_tmp.fasta include=F
     mv "$BASENAME"_tmp.fasta $1
     rm "$BASENAME".badnames
}

export -f remove_guided_contigs



