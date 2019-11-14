#!/bin/bash

VERSIONNUMBER=5.1.0.beta2.4
MODIFIEDDATE="7 November, 2019"

###################################################################################################
#
#  Amplicon DNA workflow
#
#  Version 5.1.0.beta2.4
#
#  This workflow script generates OTU tables from raw bacterial V13 and V4
#  16S rRNA and fungal ITS 1 amplicon data.
#
#  It is currently only supported for internal use at Aalborg University.
#
#  Author: Erika Yashiro, Ph.D.
#
#  Last modified: 7 November, 2019
#
###################################################################################################


# Check if user is running in Bash or Shell
if [ ! -n "$BASH" ]
    then
    echo "Please rerun this script with bash (bash), not shell (sh)."
    echo ""
    echo "Rerun the script with the -h or -help for more information."
    exit 1
fi

# Set error check
set -e
set -o pipefail

# Remove log file
#rm -f ampproc.log

#########################################################
# THREADS
#########################################################

# Define the maximum number of threads (cpus) to use.
NUMTHREADS=5

#########################################################
# OTHER PARAMS
#########################################################

# Define location of script
SCRIPTPATH="/space/users/ey/Documents/Scripts/git_work/AmpProc"
#SCRIPTPATH="/space/sharedbin/Workflows_EY"

# Define the location of the sequences folders
SEQPATH="/space/sequences/"

# Make /tmp/$USER directory as needed
mkdir -p /tmp/$USER

# Define script start date-time
STARTTIME=$(date '+%Y%m%d-%H%M%S')

# Define midas versions because they keep changing.
MIDAS3VERS="MiDAS v3.6 (2019-10-30)"
MIDAS4VERS="MiDAS v4.6 (2019-11-04)"
MIDAS3VERSABBREV="3.6"
MIDAS4VERSABBREV="4.6"


#########################################################
# HELP
#########################################################

#if [[ $1 =~ ^(-h|-help)$ ]]  => only works with bash, not shell.
Help_Function () {
# Can move the "set" parameters to after the help function so that initial command can be done with either shell or bash. the set parameters are only usable in bash, not shell.

    
    echo ""
    echo "############################################################################"
    echo "#"
    echo "#  AmpProc5  version $VERSIONNUMBER"
    echo "#"
    echo "#  This workflow script generates OTU and ZOTU tables from raw bacterial "
    echo "#  16S rRNA and fungal ITS 1 amplicon data."
    echo "#"
    echo "#  It is currently only supported for internal use at Aalborg University."
    echo "#"
    echo "#  Erika Yashiro, Ph.D."
    echo "#"
    echo "#  Last modified: $MODIFIEDDATE"
    echo "#"
    echo "############################################################################"
    echo ""
    echo ""
    echo "To run the script's full pipeline: "
    echo "   1. Make sure that you create an empty directory, where you have just the file containing your sample ID names. Call your file: samples."
    echo "   2. Type in the terminal:      AmpProc5.1"
    echo ""   
    echo "   3. Be prepared to answer the questions asked by the script." 
    echo "      Answers are case-sensitive!"
    echo "       - Whether you want OTU and ZOTU tables"
    echo "       - Whether you want single-end and/or paired-end read processing"
    echo "       - Which ribosomal region you have"
    echo "       - Which reference database to use for taxonomy prediction"
    echo "       - MiDAS samples also have a separate workflow"
    echo ""
    echo "To obtain the README file, Run Step 2. and then type quit. The README file contains the description of all the output files from the workflow, citation of external tools used, and version history."
    echo ""
    echo "To rerun the taxonomy prediction a postiori using a different reference database, run the script with the following arguments."
    echo "  -i    Input file. Must be otus.fa or zotus.fa (or single read variants)."
    echo "  -t    Input file. Must be otu/zotu/asv table without taxonomy (e.g. otutable_notax.txt)."
    echo "  -r    Reference database number for taxonomy prediction."
    echo "              3  - SILVA LTP v132"
    echo "              2  - MiDAS v2.1.3"
    echo "              3  - $MIDAS3VERS"
    echo "              4  - $MIDAS4VERS"
    echo "              5  - RDP training set v16"
    echo "              6  - UNITE fungi ITS 1&2 v8.0 (2019-02-02)"
    echo "              7  - UNITE eukaryotes ITS 1&2 v8.0 (2019-02-02)"
    echo ""
    echo "To only incorporate the new taxonomy output into an OTU table, run the script: otutab_sintax_to_ampvis.v1.2.sh (Run with -h for more information)"
    echo ""
    echo "To change the number of CPUs used by the USEARCH stages of the pipeline, adjust the number of threads when running the script."
    echo "The fasttree typically uses about 20 cores at its maximum run and this cannot be adjusted."
    echo ""
    echo "NOTE: The reference databases have been slightly reformatted in order to be compatible with the usearch10 algorithm."
    echo ""
    echo "Have a nice day!"
    echo ""
    echo ""
    exit 0
}



#########################################################
# FUNCTIONS
#########################################################

echoWithDate() {
  #echo ""
  #echo "" >> ampproc-$STARTTIME.log

  CURRENTTIME=[$(date '+%Y-%m-%d %H:%M:%S')]
  #echo "[$(date '+%Y-%m-%d %H:%M:%S')]: $1"
  echo "$CURRENTTIME: $1"
  echo "$CURRENTTIME: $1" >> ampproc-$STARTTIME.log
}

echoPlus() {
  echo $1
  echo $1 >> ampproc-$STARTTIME.log
}

Refdatabase_Name_Function () {

# The function assigns the name, version number, and path to the reference database being used.
# Requires that $REFDATABASE argument to be assigned already.

# Refdatabase_Name_Function requires $REFDATABASE
# => $TAXFILE, $TAXVERS, $REFDATAPATH

if [ $REFDATABASE == 1 ]
    then
    TAXFILE="silva"
    TAXVERS="LPT v128"
    REFDATAPATH="/space/users/ey/Documents/Amplicon_databases/SILVA_LTP/LTPs132_SSU_unaligned.sintax.fasta"
    REFNOTE="using SILVA LTP reference database."
fi

if [ $REFDATABASE == 2 ]
    then
    TAXFILE="midas2"
    TAXVERS="v2.1.3"
    REFDATAPATH="/space/users/ey/Documents/Amplicon_databases/midas_database/MiDAS_S123_2.1.3.sintax.cleaned.20180103.fasta"
    REFNOTE="using MiDAS v2 reference database."
fi
        
if [ $REFDATABASE == 3 ]
    then
    TAXFILE="midas3"
    #TAXVERS="v3.4 (2019-09-30)"
    TAXVERS="$MIDAS3VERS"
    REFDATAPATH="/space/databases/midas/MiDAS3.6_20191030/output/ESVs_w_sintax.fa"
    REFNOTE="using MiDAS $MIDAS3VERSABBREV reference database."
fi

if [ $REFDATABASE == 4 ]
    then
    TAXFILE="midas4"
    #TAXVERS="v4.4 (2019-09-30)"
    TAXVERS="$MIDAS4VERS"
    REFDATAPATH="/space/databases/midas/MiDAS4.6_20191104/output/ESVs_w_sintax.fa"
    REFNOTE="using MiDAS $MIDAS4VERSABBREV reference database."
fi
        
if [ $REFDATABASE == 5 ]
    then
    TAXFILE="rdp"
    TAXVERS="training set v16"
    REFDATAPATH="/space/users/ey/Documents/Amplicon_databases/RDP_training_set/rdp_16s_v16s_sp_sintax.cleaned.20180103.fa"
    REFNOTE="using RDP reference database."
fi
        
if [ $REFDATABASE == 6 ]
    then
    TAXFILE="uniteFUN"
    TAXVERS="v8.0 (2019-02-02)"
    REFDATAPATH="/space/users/ey/Documents/Amplicon_databases/UNITE/utax_reference_dataset_fungi_02.02.2019.corrected.fasta"
    REFNOTE="using UNITE fungi reference database."
fi

if [ $REFDATABASE == 7 ]
    then
    TAXFILE="uniteEUK"
    TAXVERS="v8.0 (2019-02-02)"
    REFDATAPATH="/space/users/ey/Documents/Amplicon_databases/UNITE/utax_reference_dataset_all_02.02.2019.corrected2.fasta"
    REFNOTE="using UNITE eukaryotes reference database."
fi
}


Find_reads_phix_Function () {

# Check that samples file exists, if yes, make sure carriage return is not used.
echoWithDate "Checking the presence of a \"samples\" file"

if [ -f "samples" ]
    then
        # remove carriage returns, add newline at the end of file if it's not there, remove empty lines and white spaces.
        dos2unix samples
        cat samples | sed -e '$a\' | sed -e '/^$/d' -e 's/ //g' > samples_tmp.txt
        echoWithDate "    Done"
    
    else
        echoPlus ""
        echoPlus "Please make sure that you have a samples list file named \"samples\" in your current directory, and then run this script again."
        echoPlus "You can also run the help function with the option -h or -help."
        echoWithDate "    Exiting script."
        echoPlus ""
        exit 1
fi    


# Check that the working directories, or files with the same names, don't exist.
#echoPlus ""
echoWithDate "Checking the presence of previous samples directories in the current directory"

if [ -f "rawdata" ]
    then
        echoPlus " A file called rawdata already exists. Do you want to remove it and continue with the script? (yes/no)"
        read ANSWER
        if [ $ANSWER = "yes" ]
            then 
            echoWithDate "    Removing rawdata file."
            rm -f rawdata
            else 
            if [ $ANSWER = "no" ]
                then
                echoWithDate "    Exiting script."
                echo ""
                exit 0
                else
                echoWithDate "Sorry I didn't understand you."
                echoWithDate "    Exiting script."
                echo ""
                exit 1
            fi
        fi
fi

if [ -d "rawdata" ]
    then
        echoPlus ""
        echoPlus "The rawdata/ directory already exists. Do you want to replace it? (yes/no)"
        read ANSWER
        if [ $ANSWER = "yes" ]
            then 
            echoWithDate "    Removing rawdata/ directory."
            rm -rf rawdata/
            else 
            if [ $ANSWER = "no" ]
                then
                echoWithDate "    Exiting script."
                echoWithDate ""
                exit 0
                else
                echoWithDate "Sorry I didn't understand you."
                echoWithDate "    Exiting script."
                echo ""
                exit 1
            fi
        fi
fi


if [ -f "phix_filtered" ]
    then
        echoPlus " A file called phix_filtered already exists. Do you want to remove it and continue with the script? (yes/no)"
        read ANSWER
        if [ $ANSWER = "yes" ]
            then 
            echoWithDate "    Removing phix_filtered file."
            rm -f phix_filtered
            else 
            if [ $ANSWER = "no" ]
                then
                echoWithDate "    Exiting script."
                echo ""
                exit 0
                else
                echoWithDate "Sorry I didn't understand you."
                echoWithDate "    Exiting script."
                echo ""
                exit 1
            fi
        fi
fi

if [ -d "phix_filtered" ]
    then 
        echoPlus ""
        echoPlus "The phix_filtered/ directory already exists. Do you want to replace it? (yes/no)"
        read ANSWER
        if [ $ANSWER = "yes" ]
            then 
            echoWithDate "    Removing phix_filtered/ directory."
            rm -rf phix_filtered/
            else 
            if [ $ANSWER = "no" ]
                then
                echoWithDate "    Exiting script."
                echoPlus ""
                exit 0
                else
                echoWithDate "Sorry I didn't understand you."
                echoWithDate "    Exiting script."
                echoPlus ""
                exit 1
            fi
        fi
fi

echoWithDate "    Done"

echoWithDate "Retrieving sequenced files and removing PhiX contamination."

# Make new working directories
  mkdir -p rawdata
  mkdir -p phix_filtered

# Find the samples from the samples file
# copy sample sequence files to current directory,
# Filter PhiX
# Path to sequences folders: $SEQPATH = /space/sequences/
 
  while read SAMPLES
  do
      # Retrieve sequenced reads
      SAMPLEDELIM="_";
      NAME=$SAMPLES;
      #find /space/sequences/ -name $NAME*R1* 2>/dev/null -exec gzip -cd {} \;
      #find /space/sequences/ -name $NAME*R1* 2>/dev/null -exec cp {} samplegz/ \;
      #find /space/sequences/ -name $NAME* 2>/dev/null -exec cp {} samplegz/ \;
      find $SEQPATH -name $NAME$SAMPLEDELIM*R1* 2>/dev/null -exec gzip -cd {} \; > rawdata/$NAME.R1.fq
      find $SEQPATH -name $NAME$SAMPLEDELIM*R2* 2>/dev/null -exec gzip -cd {} \; > rawdata/$NAME.R2.fq
      # Filter phix
      usearch11 -filter_phix rawdata/$NAME.R1.fq -reverse rawdata/$NAME.R2.fq -output phix_filtered/$NAME.R1.fq -output2 phix_filtered/$NAME.R2.fq -threads $NUMTHREADS -quiet
  done < samples_tmp.txt

#rm -rf rawdata/

echoWithDate "    Done"
    
}


Merge_Function () {

# Merge paired end reads
# Add sample name to read label (-relabel option)
# Pool samples together
# $usearch -fastq_mergepairs ../data/${Sample}*_R1.fq -fastqout $Sample.merged.fq -relabel $Sample.

#while read SAMPLES
#    do
#    NAME=$SAMPLES;
#    #usearch10 -fastq_mergepairs phix_filtered/$NAME.R1.fq -reverse phix_filtered/$NAME.R2.fq -fastqout phix_filtered/$NAME.merged.fq -relabel $NAME -quiet
#    cat phix_filtered/$NAME.merged.fq >> mergeout.fq
#    done < samples_tmp.txt

#echoPlus ""
echoWithDate "Merging paired end reads"

usearch11 -fastq_mergepairs phix_filtered/*.R1.fq -reverse phix_filtered/*.R2.fq -fastqout mergeout.fq -relabel @ -fastq_maxdiffs 15 -threads $NUMTHREADS -quiet

echoWithDate "    Done"

}

Fastqc_Function () {

# Quality filter
# Note: there is no maxlength in usearch
# V13=425 minlength
# V4=200 minlength
# ITS=200 minlength
# Single reads=250

# INFILE=fastq file of all reads after phix removal
# SEQLEN=minimum length cutoff for all reads.
# output file: QCout.fa
INFILE=$1
SEQLEN=$2

#echoPlus ""
echoWithDate "Quality filtering and removing consensus reads less than $SEQLEN bp"

usearch11 -fastq_filter $INFILE -fastq_maxee 1.0 -fastaout QCout.fa -fastq_minlen $SEQLEN -quiet -threads $NUMTHREADS

echoWithDate "    Done"

}

Fastqc_singlereads_Function () {

# Quality filter
# Label reads to samples
# Truncate reads to 250bp
# Remove reads less than 250bp

#echoPlus ""
echoWithDate "Quality filtering, truncating reads to 250bp, and removing reads less than 250bp."

# make temporary directory
mkdir phix_filtered/tempdir

# QC
# merge all sample fastq files
while read SAMPLES
    do
    NAME=$SAMPLES
    usearch11 -fastq_filter phix_filtered/$NAME.R1.fq -fastq_maxee 1.0 -fastaout phix_filtered/tempdir/$NAME.R1.QCout.fa -fastq_trunclen 250 -relabel @ -threads $NUMTHREADS -quiet
    #(-fastq_minlen 250 )
    usearch11 -fastq_filter phix_filtered/$NAME.R2.fq -fastq_maxee 1.0 -fastaout phix_filtered/tempdir/$NAME.R2.QCout.fa -fastq_trunclen 250 -relabel @ -threads $NUMTHREADS -quiet
    cat phix_filtered/tempdir/$NAME.R1.QCout.fa >> all.singlereads.nophix.qc.R1.fa
    cat phix_filtered/tempdir/$NAME.R2.QCout.fa >> all.singlereads.nophix.qc.R2.fa

    # Create concatenated fastq file of nonfiltered reads, with the sample labels
    usearch11 -fastx_relabel phix_filtered/$NAME.R1.fq -prefix $NAME. -fastqout phix_filtered/tempdir/$NAME.R1.relabeled.fq -quiet
    usearch11 -fastx_relabel phix_filtered/$NAME.R2.fq -prefix $NAME. -fastqout phix_filtered/tempdir/$NAME.R2.relabeled.fq -quiet
    cat phix_filtered/tempdir/$NAME.R1.relabeled.fq >> all.singlereads.nophix.R1.fq
    cat phix_filtered/tempdir/$NAME.R2.relabeled.fq >> all.singlereads.nophix.R2.fq
    done < samples_tmp.txt
    
#rm -r phix_filtered/tempdir

echoWithDate "    Done"

}



Dereplicate_Function () {

# Find unique read sequences and abundances => Dereplicating
#echoPlus ""
echoWithDate "Dereplicating reads"

# INFILE=all.merged.nophix.qc.fa and file variants.
# output: DEREPout.fa, which is typically renamed as uniques.fa afterwards.
INFILE=$1
usearch11 -fastx_uniques $INFILE -sizeout -fastaout DEREPout.fa -relabel Uniq -quiet

echoWithDate "    Done"

}



#(EY) Remove primer sequences, use cutadapt? leave blank for now.
    # cutadapt: http://cutadapt.readthedocs.io/en/stable/guide.html
    # other things out there: Bamclipper https://www.nature.com/articles/s41598-017-01703-6
    # edge effects: https://bmcgenomics.biomedcentral.com/articles/10.1186/1471-2164-15-1073
    # http://www.usadellab.org/cms/?page=trimmomatic
    # https://github.com/ezorita/seeq

# (EY) trim reads to minlen350? => minlen200 and stay generic for v13 and v4


Prefilter_60pc_Function () {

# Prefilter reads <60% ID to reference dataset from full Silva
#echoPlus ""
echoWithDate "Prefiltering reads that are <60% similar to reference reads"
echo ""

# INFILE=uniques.fa or otus.fa
# output: prefilt_out.fa
INFILE=$1
REF_DATABASE="/space/users/ey/Documents/Amplicon_databases/gg_13_8_otus97/97_otus.fasta"

#usearch10 -closed_ref $INFILE -db /space/users/ey/Documents/gg_13_8_otus97/97_otus.fasta -strand both -id 0.6 -mapout closed_mapped.txt
#usearch10 -usearch_global $INFILE -db $REF_DATABASE -strand both -id 0.6 -maxaccepts 1 -maxrejects 256 -matched prefilt_out.tmp -threads $NUMTHREADS -quiet
usearch11 -usearch_global $INFILE -db $REF_DATABASE -strand both -id 0.6 -maxaccepts 1 -maxrejects 8 -matched prefilt_out.fa -threads $NUMTHREADS

# relabel the unique, prefiltered reads so that the reads are in numerical order.
#usearch10 -fastx_relabel prefilt_out.tmp -prefix Prefilt -fastaout prefilt_out.fa -keep_annots
#usearch10 -sortbysize prefilt_out.tmp -fastaout prefilt_out.fa -quiet

#rm prefilt_out.tmp

echo ""

echoWithDate "    Done"

}


Cluster_otus_Function () {

# Make 97% OTUs and filter chimeras, use de novo
# cluster_otus: OTU clustering with chimera filtering (UPARSE-OTU algorithm)
#echoPlus ""
echoWithDate "Making 97% OTUs and filter chimeras"

# INFILE=prefilt_out.fa or uniques.fa
# output: otus.fa
INFILE=$1
usearch11 -cluster_otus $INFILE -otus otus.fa -relabel OTU -minsize 2 -quiet

echoWithDate "    Done"

}


Unoise3_Function () {

# Denoise: predict biological sequences and filter chimeras
#echoPlus ""
echoWithDate "Creating ZOTUs of dereplicated reads file using UNOISE3"

# INFILE=prefilt_out.fa
# output: zotus.fa
INFILE=$1
usearch11 -unoise3 $INFILE -zotus zotus.fa -quiet

echoWithDate "    Done"

}


Make_otutable_Function () {

# Make OTU table
# Ensure that taxonomy file is available
# OTU table without taxonomy information

#echoPlus ""
echoWithDate "Making an OTU table"

# FASTAFILE=all.merged.nophix.qc.fa (output from Fastqc_singlereads_Function)
# OTUSFILE=otus.fa (output from Cluster_otus_function)
# SINTAX=sintax_out.otus.txt  (output from Predict_taxonomy_Function)
FASTAFILE=$1
OTUSFILE=$2
SINTAX=$3
usearch11 -otutab $FASTAFILE -otus $OTUSFILE -otutabout otutable_notax.txt -id 0.97 -threads $NUMTHREADS -quiet -sample_delim .

bash $SCRIPTPATH/otutab_sintax_to_ampvis.v1.2.sh -i otutable_notax.txt -t $SINTAX -r $REFDATABASE

rm otutable_notax.txt
#mv otutable_notax_sorted.txt otutable_notax.txt
mv otutable_notax.sorted.txt otutable_notax.txt
mv otutable_notax_$REFDATABASE.txt otutable.txt

echoWithDate "    Done"

}


Make_zotutable_Function () {

# Make ZOTU table
# Ensure that taxonomy file is available

#echoPlus ""
echoWithDate "Making a zOTU table"
 
# FASTAFILE=all.merged.nophix.qc.fa (output from Fastqc_Function)
# OTUSFILE=zotus.fa (output from Unoise3_Function)
# SINTAX=sintax_out.otus.txt  (output from Predict_taxonomy_Function)
FASTAFILE=$1
ZOTUSFILE=$2
SINTAX=$3
sed 's/Zotu/Otu/g' $ZOTUSFILE > zotus.tmp
#usearch10 -otutab $FASTAFILE -otus zotus.tmp -otutabout zotutable_notax.txt -id 0.97 -threads $NUMTHREADS -quiet -sample_delim .
usearch11 -otutab $FASTAFILE -zotus $ZOTUSFILE -otutabout zotutable_notax.txt -id 0.97 -threads $NUMTHREADS -quiet -sample_delim .
#sed -i 's/Otu/Zotu/g' zotutable_notax.txt
rm zotus.tmp

bash $SCRIPTPATH/otutab_sintax_to_ampvis.v1.2.sh -i zotutable_notax.txt -t $SINTAX -r $REFDATABASE

rm zotutable_notax.txt
#mv otutable_notax_sorted.txt zotutable_notax.txt
mv zotutable_notax.sorted.txt zotutable_notax.txt
mv zotutable_notax_$REFDATABASE.txt zotutable.txt
#sed -i 's/Otu/Zotu/g' zotutable.txt
#sed -i 's/Otu/Zotu/g' zotutable_notax.txt

echoWithDate "    Done"

}

Predict_taxonomy_Function () {

# Predict taxonomy, set to multithreads on 8 cores
#usearch10 -sintax all.merged.qc.nophix.uniques.otus.fa -db /space/databases/midas/MiDAS_S123_2.1.3.sintax.fasta -strand both -tabbedout all.merged.qc.nophix.uniques.otus.sintax.txt -sintax_cutoff 0.8 -threads 8 ‑notrunclabels 
INFILE=$1
ELEMENT=$2
# INFILE is the otus.fa file
# $ELEMENT is either otus or zotus

#echoPlus ""
echoWithDate "Predicting taxonomy (Classifying the $ELEMENT) using SINTAX"

# Echo reference database to be used for taxonomy predictions
echoPlus "$REFNOTE"

# Run usearch
    usearch11 -sintax $INFILE -db $REFDATAPATH -strand both -tabbedout sintax_out.txt -sintax_cutoff 0.8 -threads $NUMTHREADS -quiet 2>>ampproc-$STARTTIME.log

echoWithDate "    Done"

}


Taxonomy_reports_Function () {
# Taxonomy summary reports
# INFILE1=sintax_out.txt
# INFILE2=otutable_notax.txt
# OUTFILE=output file prefix

INFILE1=$1
INFILE2=$2
OUTFILE=$3

#echoPlus ""
echoWithDate "Generating $OUTFILE taxonomy summary"

# if no taxonomy consensus was found for an otu and the 4th column is blank, then sintax_summary causes error, so add something.
sed -i 's/+\t$/+\td:__unknown__/g' $INFILE1
sed -i 's/-\t$/-\td:__unknown__/g' $INFILE1

usearch11 -sintax_summary $INFILE1 -otutabin $INFILE2 -rank p -output $OUTFILE.phylum_summary.txt -quiet
echoPlus ""
echoPlus "    Output phlyum summary: $OUTFILE.phylum_summary.txt"

usearch11 -sintax_summary $INFILE1 -otutabin $INFILE2 -rank c -output $OUTFILE.sintax.class_summary.txt -quiet
echoPlus "    Output class summary: $OUTFILE.sintax.class_summary.txt"

usearch11 -sintax_summary $INFILE1 -otutabin $INFILE2 -rank o -output $OUTFILE.sintax.order_summary.txt -quiet
echoPlus "    Output order summary: $OUTFILE.sintax.order_summary.txt"

usearch11 -sintax_summary $INFILE1 -otutabin $INFILE2 -rank f -output $OUTFILE.sintax.family_summary.txt -quiet
echoPlus "    Output family summary: $OUTFILE.sintax.family_summary.txt"

usearch11 -sintax_summary $INFILE1 -otutabin $INFILE2 -rank g -output $OUTFILE.sintax.genus_summary.txt -quiet
echoPlus "    Output genus summary: $OUTFILE.sintax.genus_summary.txt"

echoPlus ""
echoWithDate "    Done"

}

MaketreeProk_Function() {
    # INFILE=otus.fa
    # ELEMENT=suffix for type of otu/zotu

    INFILE=$1
    ELEMENT=$2
    REP_ALIGNED_PATH="/space/users/ey/Documents/Amplicon_databases/core_set_aligned.fasta.imputed"
    USER_PATH=`echo $PWD`

    #echoPlus ""
    echoWithDate "Aligning the bacterial sequenced reads using PyNAST with QIIME v1 native parameters."
    # Using PyNAST in Unifrac 1.9.1
    align_seqs.py -i $USER_PATH/$INFILE -m pynast -t $REP_ALIGNED_PATH -o $USER_PATH/aligned_seqs_$ELEMENT/ -p 0.40

    #echoPlus ""
    echoWithDate "Generating FastTree maximum likelihood tree of the bacterial sequenced reads with QIIME native parameters"
    echoPlus ""
    
    # Qiime 1.8 / 1.9 default params is fasttree default params.
    # Set the number of threads for fasttreeMP to 16 cores
    #export OMP_NUM_THREADS=16
    
    #fasttree
    INFILE2=`echo $INFILE | sed 's/.fa$//g'`
    fasttreeMP -nt aligned_seqs_$ELEMENT/${INFILE2}_aligned.fasta > aligned_seqs_$ELEMENT/$INFILE2.$ELEMENT.tre
    
    # Reset the OMP threads
    #export OMP_NUM_THREADS=""
    
    # or: make_phylogeny.py -i $USER_PATH/aligned_seqs/${INFILE2}_aligned.fasta -o $USER_PATH/$INFILE.tre

    echo "    "
    echoWithDate "    Output files of alignment and tree are in aligned_seqs_$ELEMENT/"
}

MaketreeFung_Function() {
    # INFILE=otus.fa
    # ELEMENT=suffix for type of otu/zotu

    INFILE=$1
    ELEMENT=$2
    USER_PATH=`echo $PWD`

    #echoPlus ""
    echoWithDate "Using USEARCH maximum linkage clustering to build OTU tree"
    mkdir aggr_tree_$ELEMENT

    usearch10 -cluster_agg $INFILE -treeout aggr_tree_$ELEMENT/$ELEMENT.cluster.tre -id 0.80 -linkage max -quiet
    
    echoPlus ""
    echoPlus "   Warning: Fungal ITS regions are too variable for proper phylogenetic tree. Therefore the maximum linkage tree will be used for generating phlyogeny-based beta diversity matrices."
    echoPlus "    "
    echoWithDate "    Output files of linkage tree tree are in aggr_tree_$ELEMENT/"
}


MaketreeWrapper_Function() {
    # This function is a wrapper to decide whether to run the MaketreeFung_Function or the MaketreeProk_Function.

    # INFILE=otus.fa
    # ELEMENT=suffix for type of otu/zotu/asv R1/R2

    INFILE=$1
    ELEMENT=$2
    USER_PATH=`echo $PWD`

   
     if [[ $AMPREGION =~ ^(V4|V13)$ ]]
        then
        #Align reads and build prokaryotic tree
        MaketreeProk_Function $INFILE $ELEMENT
     fi

     if [ $AMPREGION = "ITS" ]
        then
        # Build clustering tree for fungi / other eukaryotes
        MaketreeFung_Function $INFILE $ELEMENT
     fi

echoWithDate "    Done"

}

Betadiv_Function () {
# Build phylogenetic tree, probably for use in calculating unifrac. Therefore, using fasttree.
# As of December 2017, Current version installed on Dragon is FastTree v2.1.7.
# Need the otus.fa as INFILE,and and otutable_notax.txt as input files.
# export OMP_NUM_THREADS=16
#   This will make the fasttreeMP run only 16 threads instead of all CPUs on the server.

# Note that this kind of error message could occur if there is only 1 otu that passed the zotu filter: /usr/local/lib/python2.7/dist-packages/cogent/maths/unifrac/fast_tree.py:369: RuntimeWarning: invalid value encountered in double_scalars
#  (branch_lengths*logical_or(i,j)).sum())


# INFILE=otus.fa
# OTUTABLE=otutable_notax.txt
# ELEMENT=suffix for type of otu/zotu
INFILE=$1
OTUTABLE=$2
ELEMENT=$3
USER_PATH=`echo $PWD`

INFILE2=`echo $INFILE | sed 's/.fa$//g'`

#echoPlus ""
echoWithDate "Building beta diversity matrices."

# Calculate number of reads per sample
#echoPlus ""
echoWithDate "    Normalizing the OTU table to 1000"
OTUTABLE2=`echo $OTUTABLE | sed -e 's/.txt$//g' -e 's/.tsv$//g'`
usearch11 -alpha_div $OTUTABLE -output $OTUTABLE2.number_reads_per_sample.txt -metrics reads -quiet

  # Check that at least one sample has at least 1000 reads total.
SAMPLESIZE=`awk -F "\t" 'NR>1{ if ($2 > 1000) {print "OVER1000"; exit} }' $OTUTABLE2.number_reads_per_sample.txt`
  # Check how many samples have at least 1000 reads total.
SAMPLENUM=`awk -F "\t" 'NR>1{ if ($2 > 1000) {print "OVER1000"} }' $OTUTABLE2.number_reads_per_sample.txt | wc -l`


if [ "$SAMPLESIZE" = "OVER1000" ]
  then
  # Normalize OTU table to 1000 reads per sample
  usearch11 -otutab_trim $OTUTABLE -min_sample_size 1000 -output $OTUTABLE2.tmp -quiet
  usearch11 -otutab_rare $OTUTABLE2.tmp -sample_size 1000 -output $OTUTABLE2.norm1000.txt -quiet
  rm $OTUTABLE2.tmp
  #echoPlus ""
  echoWithDate "    Output of normalized OTU table: $OTUTABLE2.norm1000.txt"
  else
  #echoPlus ""
  echoWithDate "   Cannot normalize OTU table to 1000 reads per sample because none of the samples have >1000 reads." 
  echoWithDate "   Using only non-normalized OTU table."
fi

if [[ $AMPREGION =~ ^(V4|V13)$ ]]
    then
    # Make sure that a tree has already been generated.

    echoPlus ""
    echoPlus "   Warning: The R package Ampvis uses the Generalized UniFrac instead of the original weighted and unweighted UniFrac equations implemented in QIIME version 1.x.x."
    echoPlus ""
    echoWithDate "   Generating beta diversity matrices: Bray Curtis, original version of weighted & unweighted UniFrac from Fasttree tree, Jaccard (abundance-based), and Jaccard binary (presence-absence)"

    # Create betadiv folder

    mkdir beta_div_$ELEMENT

    # Convert classic otu table to biom format
    biom convert -i $OTUTABLE -o $OTUTABLE.biom --table-type="OTU table" --to-hdf5

    # Run Qiime 1.9.1 beta_diversity script for UniFrac
    beta_diversity.py -i $OTUTABLE.biom -m weighted_unifrac,unweighted_unifrac -o beta_div_$ELEMENT/ -t aligned_seqs_$ELEMENT/$INFILE2.$ELEMENT.tre
    # Change file names of output matrices
    mv beta_div_$ELEMENT/weighted_unifrac_$OTUTABLE.txt beta_div_$ELEMENT/$ELEMENT.weighted_unifrac.txt
    mv beta_div_$ELEMENT/unweighted_unifrac_$OTUTABLE.txt beta_div_$ELEMENT/$ELEMENT.unweighted_unifrac.txt

    # Run Usearch for Bray Curtis
    usearch11 -beta_div $OTUTABLE -metrics bray_curtis,jaccard,jaccard_binary -filename_prefix beta_div_$ELEMENT/$ELEMENT. -quiet
    
   if [ "$SAMPLESIZE" = "OVER1000" ] && [ "$SAMPLENUM" -gt 1 ]
      then
      # Convert normalized otu table to biom format
      biom convert -i $OTUTABLE2.norm1000.txt -o $OTUTABLE2.norm1000.biom --table-type="OTU table" --to-hdf5

      # Run Qiime script for UniFrac matrices
      beta_diversity.py -i $OTUTABLE2.norm1000.biom -m weighted_unifrac,unweighted_unifrac -o beta_div_norm1000_$ELEMENT/ -t aligned_seqs_$ELEMENT/$INFILE2.$ELEMENT.tre
      # Change file name of output matrices
      mv beta_div_norm1000_$ELEMENT/weighted_unifrac_$OTUTABLE2.norm1000.txt beta_div_norm1000_$ELEMENT/$ELEMENT.weighted_unifrac.txt
      mv beta_div_norm1000_$ELEMENT/unweighted_unifrac_$OTUTABLE2.norm1000.txt beta_div_norm1000_$ELEMENT/$ELEMENT.unweighted_unifrac.txt

      # Run Usearch for Bray Curtis matrix
      usearch11 -beta_div $OTUTABLE2.norm1000.txt -metrics bray_curtis,jaccard,jaccard_binary -filename_prefix beta_div_norm1000_$ELEMENT/$ELEMENT. -quiet
      else
      #echoPlus ""
      echoWithDate "   Note: Beta diversity matrices from normalized OTU table could not be generated."
   fi
    
    
    #echoPlus ""
    echoWithDate "    Output files of beta diversity in beta_div_$ELEMENT/"

   if [ "$SAMPLESIZE" = "OVER1000" ] && [ "$SAMPLENUM" -gt 1 ]
      then
    echoWithDate "    Output files of beta diversity of normalized data in beta_div_norm1000_$ELEMENT/"
   fi
fi

if [ $AMPREGION = "ITS" ]
    then

    # Check that there is more than 2 OTUs in the OTU table
    NUMOTUS=`grep -c ">" $INFILE || true`

    if [ $NUMOTUS -le 1 ]
      then
      #echoPlus ""
      echoWithDate "   There is not enough $ELEMENT to generate beta diversity output. No matrices generated"
      else
       # Make sure that a cluster tree has been generated.

       #echoPlus ""
       echoWithDate "   Generating beta diversity matrices: Bray Curtis, weighted & unweighted UniFrac from clustering tree, Jaccard (abundance-based), and Jaccard binary (presence-absence)"

       
       # Calculate beta diversity matrices
       mkdir beta_div_$ELEMENT
       usearch11 -beta_div $OTUTABLE -metrics bray_curtis,unifrac,unifrac_binary,jaccard,jaccard_binary -tree aggr_tree_$ELEMENT/$ELEMENT.cluster.tre -filename_prefix beta_div_$ELEMENT/$ELEMENT. -quiet
    
      if [ $SAMPLESIZE = "OVER1000" ] && [ "$SAMPLENUM" -gt 1 ]
         then
         # Calculate beta diveristy matrices for normalized otu table of normalized otu table is large enough.
         usearch11 -beta_div $OTUTABLE2.norm1000.txt -metrics bray_curtis,unifrac,unifrac_binary,jaccard,jaccard_binary -tree aggr_tree_$ELEMENT/$ELEMENT.cluster.tre -filename_prefix beta_div_$ELEMENT/$ELEMENT.norm1000_ -quiet
         else
         #echoPlus ""
         echoWithDate "   Note: Beta diversity matrices from normalized OTU table could not be generated."
      fi
        
       #echoPlus ""
       echoWithDate "    Output files of clustering: aggr_tree_$ELEMENT/"
       echoWithDate "    Output files of beta diversity in beta_div_$ELEMENT/"
   fi
fi

echoWithDate "    Done"

}


Cleanup_Function () {

rm -r rawdata
rm -r phix_filtered
rm samples_tmp.txt
rm *.nophix.*
rm -f prefilt_out.*
rm sintax_out.*
rm -f *.biom
rm -f uniques.*
rm -f otus.R1.tmp
rm -f otus.R2.tmp
rm -f otus.tmp

mkdir taxonomy_summary
mv *_summary.txt taxonomy_summary/.

}

WORKFLOW_MIDAS_Function () {

echoWithDate "Running MiDAS ASV workflow to generate raw table and taxonomy"
echoWithDate "Please note that the MiDAS workflow is only for bacteria from wastewater sludge and digesters. For all other sample types and/or organism groups, you need to use the AmpProc standard workflow."

#echo "refdatapath: $REFDATAPATH"
# Run Kasper's ASV script
bash $SCRIPTPATH/ASVpipeline.sh $REFDATAPATH $NUMTHREADS

echoWithDate "ASVpipeline finished."

# Append asv table to sintax taxonomy
echoWithDate "Using AmpProc to generate ASV table for AmpVis"
echoPlus ""

mv ASVtable.tsv ASVtable_notax.tsv

bash $SCRIPTPATH/otutab_sintax_to_ampvis.v1.2.sh -i ASVtable_notax.tsv -t ASVs.R1.sintax -r MIDAS

mv ASVtable_notax_MIDAS.txt ASVtable_MIDAS.tsv
rm ASVtable_notax.tsv
mv ASVtable_notax.sorted.txt ASVtable_notax.tsv

# Align sequences, build tree
  if [ $MAKETREE = "yes" ]
      then
      # Arbitrarily set ampregion to v13 to adapt to tree-building function
      AMPREGION=V13
      # Run tree-building wrapper function
      MaketreeWrapper_Function ASVs.R1.fa ASVS
  fi

# Generate beta diversity matrices that can be fed into Ampvis or R base.
  if [ $BETADIV = "yes" ]
      then
      Betadiv_Function ASVs.R1.fa ASVtable_notax.tsv ASVS
  fi

echoWithDate ""

echoWithDate "MiDAS workflow is done. Have a nice day!"

exit 0

}


Run_Time_Params_Function () {

# Write out the command and arguments into a log file.
# => ammproc_params-'date-time'.log

# Requires $RUNOPTS = nothing, APOSTIORI or ASVPIPELINE runs

printf "File created: " > ampproc_params-$STARTTIME.log
date >> ampproc_params-$STARTTIME.log
echo "" >> ampproc_params-$STARTTIME.log

echo "AmpProc5 version: $VERSIONNUMBER" >> ampproc_params-$STARTTIME.log

echo "" >> ampproc_params-$STARTTIME.log

if [ "$RUNOPTS" = "APOSTIORI" ]
   then
   echo "A postiori run to append new taxonomy to existing community counts table." >> ampproc_params-$STARTTIME.log
   echo "" >> ampproc_params-$STARTTIME.log
fi

if [ "$RUNOPTS" = "ASVPIPELINE" ]
   then
   echo "MiDAS ASV pipeline run by AmpProc." >> ampproc_params-$STARTTIME.log
   echo "" >> ampproc_params-$STARTTIME.log
fi

  # full command string
printf "Full command: " >> ampproc_params-$STARTTIME.log
echo "$0 $@" >> ampproc_params-$STARTTIME.log

echo "What workflow do you want to run (MiDAS / Standard)?            $WORKFLOW" >> ampproc_params-$STARTTIME.log
echo "Generate a ZOTU table using UNOISE3?                            $ZOTUS" >> ampproc_params-$STARTTIME.log
echo "Process single-end reads (SR) and/or paired-end reads (PE)?     $SINGLEREADS" >> ampproc_params-$STARTTIME.log
echo "Amplicon region?                                                $AMPREGION" >> ampproc_params-$STARTTIME.log
echo "Reference database to use for taxonomy prediction?              $REFDATABASE ) $TAXFILE $TAXVERS" >> ampproc_params-$STARTTIME.log
echo "Number of threads:                                              $NUMTHREADS" >> ampproc_params-$STARTTIME.log
echo "Make a phylo/cluster tree:                                      $MAKETREE" >> ampproc_params-$STARTTIME.log
echo "Generate beta diversity output:                                 $BETADIV" >> ampproc_params-$STARTTIME.log

}

#########################################################
# ARGUMENTS
#########################################################


# Arguments: help/h, presence of samples file, or go with a postiori taxonomy options.
if [[ "$1" =~ ^(-help|-h)$ ]]
    then
    Help_Function
    else
    if [[ "$1" =~ ^(-v|-V|--version)$ ]]
        then
        echo $VERSIONNUMBER
        exit
    else
    # if there are arguments present
    if [ $1 ]
        then
        echoWithDate ""
        echoWithDate "Running: 16S workflow version $VERSIONNUMBER"
        echoWithDate "A postiori taxonomy assignment"
        #echo "To incorporate new taxonomy into OTU table, run otutab_sintax_to_ampvis.v1.1.sh"
        #date
        while getopts :i:t:r: option
            do
            case "${option}"
            in
            i) OTUINFILE=${OPTARG} ;;
            t) OTUTAB=${OPTARG} ;;
            r) TAX=${OPTARG} ;;
            #o) OTUOUTFILE=${OPTARG} ;;
            #h) Help_Function ;;
            \?) echo ""
                echo "Invalid option: -$OPTARG" >&2 
                echo "Check the help manual using -help or -h"
                echo "Exiting script."
                echo ""
                exit 1 ;;
            :) echo ""
               echo "Option -$OPTARG requires an argument"
               echo "Check the help manual using -help or -h"
               echo "Exiting script."
               echo ""
               exit 1 ;;
            esac
        done
        
        if [ ! -f $OTUINFILE ]
            then 
            echo ""
            echo "Input file $OTUINFILE does not exist. Exiting script."
            echo ""
            exit 1
        fi

        if [ ! -f $OTUTAB ]
            then
            echo ""
            echo "Input file $OTUTAB does not exist. Exiting script."
            echo ""
            exit 1
        fi
        
	if [ $TAX -lt 1 ] || [ $TAX -gt 7 ]
            then
            echo ""
            echo "Taxonomy needs to be selected (1,2,3,4,5,6 or 7). Check -help or -h for more information. Exiting script."
            echo ""
            exit 1
        fi
        
        # Assign ref database name and path
        REFDATABASE=$TAX
        Refdatabase_Name_Function
        
        # Write command parameters to log
        RUNOPTS=APOSTIORI
        Run_Time_Params_Function

        # Run taxonomy prediction with specified reference database
        PREDTYPE=`echo $OTUINFILE | sed 's/\..*//g'`
        Predict_taxonomy_Function $OTUINFILE $PREDTYPE
        # input file radical, remove file extension
        FILERAD=`echo $OTUINFILE | sed -e 's/\.fa$//g' -e 's/\.fas$//g' -e 's/\.fasta$//g'`
        TABFILERAD=`echo $OTUTAB | sed 's/\..*//g'`
        mv sintax_out.txt $FILERAD.sintax.$TAXFILE.txt
        # Append new sintax to otu table
        $SCRIPTPATH/otutab_sintax_to_ampvis.v1.2.sh -i $OTUTAB -t $FILERAD.sintax.$TAXFILE.txt -r $TAXFILE
        # Remove extraneous sorted no-tax otu table
        rm $TABFILERAD.sorted.txt
        # If "_notax" is present in output file, remove that.
        TABFILERADNOTAX=`echo $TABFILERAD | sed 's/_notax//g'`
        mv ${TABFILERAD}_${TAXFILE}.txt ${TABFILERADNOTAX}_${TAXFILE}.txt
        echoWithDate "Output files of the OTU/ZOTU/ASV taxonomy assignment: $FILERAD.sintax.$TAXFILE.txt, ${TABFILERADNOTAX}_${TAXFILE}.txt"
        #date
        echoPlus ""
        exit 0
        
        else
        if [ ! -f "samples" ]
        then 
        echoWithDate "samples file does not exist. Check -help or -h for more information. Exiting script."  
        echoPlus ""
        exit 1
	fi
    fi
fi
fi
    

#########################################################
# MAIN WORKFLOW
#########################################################

# Define ZOTUS = yes/no
# Define single read = yes/no/both (SINGLEREADS)
# Define amplicon region = V13/V4/V35/ITS (AMPREGION)
# Define reference database = 1/2/3/4/5/6/7 (REFDATABASE)


#########################################################
# Questions
#########################################################

clear
echoWithDate ""
echoPlus "Running: AmpProc5 version $VERSIONNUMBER"
echoPlus ""
echoPlus "WARNING: Please note that this version uses a different workflow than v.4.3, so you are advised to rerun this script on your older datasets if you wish to proceed with comparative analyses with the older data."
echoPlus ""
echoPlus "Use the -h or -help options to run the Help function"
echoPlus ""
echoPlus "Read the README file for more information on how to cite this workflow."
echoPlus "Description of all the output files are also found in the README file."
echoPlus ""
echoPlus "This tool is for academic use only."
echoPlus ""

# Copy the README file
#cp /space/users/ey/Documents/Scripts/amplicon_workflow/README_amplicon.workflow_v$VERSIONNUMBER.txt .
cp $SCRIPTPATH/README.md .

# Standard or MiDAS workflow
echoPlus ""
echoPlus "What workflow do you want to run?"
echoPlus "        S  - Standard workflow"
echoPlus "        M  - MiDAS ASV workflow"
read WORKFLOW
echo $WORKFLOW >> ampproc-$STARTTIME.log

# Check that the question answer is script readable
if [[ ! "$WORKFLOW" =~ ^(S|M)$ ]]
   then
   echoPlus ""
   echoPlus "Workflow type: $WORKFLOW is an invalid argument."
   echoPlus "Sorry I didn't understand what you wrote. Please also make sure that you have the correct upper/lower case letters."
   echoWithDate "    Exiting script"
   exit 1
fi

# Run Midas workflow if selected
   if [ $WORKFLOW = "M" ]
     then

     # Define tree building (yes/no)
     echoPlus ""
     echoPlus "Do you want to build a phylogenetic (prokaryotes) or cluster (eukaryotes) tree?"
     echoPlus "        yes - Build a tree"
     echoPlus "        no  - Don't build a tree"
     read MAKETREE
     echo "$MAKETREE" >> ampproc-$STARTTIME.log

     # Run diagnostics beta div function
     echoPlus ""
     echoPlus "Do you want to generate beta diversity matrices? (full and rarefied to 1000 reads per sample)"
     echoPlus "Note: the output can be directly used to generate ordination graphs or hierarchical dendrograms."
     echoPlus "        yes - Run betadiv"
     echoPlus "        no  - Skip betadiv"
     read BETADIV
     echo "$BETADIV" >> ampproc-$STARTTIME.log


     if [[ ! "$MAKETREE" =~ ^(yes|no)$ ]]
         then
         echoPlus ""
         echoPlus "Tree making: $MAKETREE invalid argument."
         echoPlus "Sorry I didn't understand what you wrote. Please also make sure that you have the correct upper/lower case letters."
         echoPlus "You can also run the help function with the option -help or -h."
         echoWithDate "    Exiting script"
         echoPlus ""
         exit 1
     fi

     if [[ ! "$BETADIV" =~ ^(yes|no)$ ]]
         then
         echoPlus ""
         echoPlus "Betadiversity: $BETADIV invalid argument."
         echoPlus "Sorry I didn't understand what you wrote. Please also make sure that you have the correct upper/lower case letters."
         echoPlus "You can also run the help function with the option -help or -h."
         echoWithDate "    Exiting script"
         echoPlus ""
         exit 1
     fi

     # Automatically turn on tree building if betadiversity is switched on.
     if [ $BETADIV = "yes" ]
        then
        MAKETREE="yes"
     fi


    # Define reference database for taxonomy prediction of OTUs (REFDATABASE)
    echoPlus ""
    echoPlus "Which reference database do you want to use for taxonomy prediction?"
    echoPlus "        1  - $MIDAS3VERS"
    echoPlus "        2  - $MIDAS4VERS" 
    echoPlus ""
    echoPlus "Note: MiDAS datasets are for waste water treatment systems."
    echoPlus "For general bacteria and archaea, use SILVA LTP"

    read MIDASDATABASE
    echo "$MIDASDATABASE" >> ampproc-$STARTTIME.log

    if [[ "$MIDASDATABASE" -lt 1 ]] || [[ "$MIDASDATABASE" -gt 2 ]]
    then
    echoPlus ""
    echoPlus "Reference database: $MIDASDATABASE invalid argument."
    echoPlus "Sorry I didn't understand what you wrote. Please make sure that you select the correct database."
    echoPlus "You can also run the help function with the option -help or -h."
    echoWithDate "    Exiting script"
    echoPlus ""
    exit 1
    fi

    # Define number of threads to use (NUMTHREADS)
    echoPlus ""
    echoPlus "How many CPUs do you want to use at maximum run?"
    echoPlus "Dragon (up to 70), Coco and Peanut (up to 10)"
    echoPlus "If unsure, then start the run with 5 threads"
    read NUMTHREADS
    echo "$NUMTHREADS" >> ampproc-$STARTTIME.log

     # Automatically define reference database.
     if [ $MIDASDATABASE -eq 1 ]
       then
       REFDATABASE=3
       else
       REFDATABASE=4
     fi

     # Adjust number of threads to ASVpipeline settings.
     #NUMTHREADS=$((`nproc`-2))

     # Adjust params arguments
     SINGLEREADS=R1
     AMPREGION=Undefined
     ZOTUS=ASVs

     # Extract Reference database name, version, and path
     Refdatabase_Name_Function

     # Write command parameters to log
     RUNOPTS=ASVPIPELINE
     Run_Time_Params_Function

     # Run ASV pipeline workflow
     WORKFLOW_MIDAS_Function
     else
     if [ $WORKFLOW = "S" ]
       then
       echoPlus ""
       echoPlus "Continuing with standard workflow"
     fi
fi

# Continue with STANDARD workflow

# Define ZOTUs = yes/no
echoPlus ""
echoPlus "Do you want to generate an OTU table and/or a ZOTU table using UNOISE3?"
echoPlus "        otu  - Generate OTU table"
echoPlus "        zotu - Generate ZOTU table"
echoPlus "        both - Generate OTU and ZOTU table"
echoPlus "        quit - Quit the script so I can go and read up on UNOISE3"
read ZOTUS
echo "$ZOTUS" >> ampproc-$STARTTIME.log

# Check that the question answers are script readable.
# note: arg between quotes means it can be nothing without producing error.
if [[ ! "$ZOTUS" =~ ^(otu|zotu|both|quit)$ ]]
    then
    echoPlus ""
    echoPlus "OTU / ZOTU table: $ZOTUS is an invalid argument."
    echoPlus "Sorry I didn't understand what you wrote. Please also make sure that you have the correct upper/lower case letters."
    echoPlus "You can also run the help function with the option -help or -h."
    echoWithDate "    Exiting script"
    echoPlus ""
    exit 1
    else
    if [ $ZOTUS = "quit" ]
        then
        echoPlus ""
        echoWithDate "    Exiting script"
        echoPlus ""
        exit 0
    fi
fi


# Define single read process = SR/PE/both (SINGLEREADS)
echoPlus ""
echoPlus "Do you want to process single-end reads or paired-end reads?"
echoPlus "Select to run single end reads if you want to control for species that have very long variable regions between the forward and reverse primers. These species can be rare in the community but will get filtered out if the paired end reads do not overlap."
echoPlus "If you have paired-end amplicons that are too long to stitch together, you also need to use the single read option."
echoPlus "        SR   - Process only single reads"
echoPlus "        PE   - Process only paired-end reads"
echoPlus "        both - process both single reads and paired-end reads"
read SINGLEREADS
echo "$SINGLEREADS" >> ampproc-$STARTTIME.log

# Define amplicon region = V13/V4/ITS (AMPREGION)
echoPlus ""
echoPlus "What genomic region does your PCR amplicons amplify?"
echoPlus "        V13 - Bacterial 16S rRNA hypervariable regions 1 & 3"
echoPlus "        V4  - Bacterial 16S rRNA hypervariable region 4"
echoPlus "        V35 - Archaeal 16S rRNA hypervariable region 3 to 5"
echoPlus "        ITS - Fungal ribosomal ITS 1 region"
read AMPREGION
echo "$AMPREGION" >> ampproc-$STARTTIME.log

# Define reference database for taxonomy prediction of OTUs (REFDATABASE)
echoPlus ""
echoPlus "Which reference database do you want to use for taxonomy prediction?"
echoPlus "        1  - SILVA LTP v132"
echoPlus "        2  - MiDAS v2.1.3"
echoPlus "        3  - $MIDAS3VERS"
echoPlus "        4  - $MIDAS4VERS"
echoPlus "        5  - RDP training set v16"
echoPlus "        6  - UNITE fungi ITS 1&2 v8.0 (2019-02-02)"
echoPlus "        7  - UNITE eukaryotes ITS 1&2 v8.0 (2019-02-02)"
echoPlus ""
echoPlus "Note: MiDAS datasets are for waste water treatment systems."
echoPlus "For general bacteria and archaea, use SILVA LTP"

read REFDATABASE
echo "$REFDATABASE" >> ampproc-$STARTTIME.log

# Define number of threads to use (NUMTHREADS)
echoPlus ""
echoPlus "How many CPUs do you want to use at maximum run?"
echoPlus "Dragon (up to 70), Coco and Peanut (up to 10)"
echoPlus "If unsure, then start the run with 5 threads"
read NUMTHREADS
echo "$NUMTHREADS" >> ampproc-$STARTTIME.log

# Define tree building (yes/no)
echoPlus ""
echoPlus "Do you want to build a phylogenetic (prokaryotes) or cluster (eukaryotes) tree?"
echoPlus "        yes - Build a tree"
echoPlus "        no  - Don't build a tree"
read MAKETREE
echo "$MAKETREE" >> ampproc-$STARTTIME.log

# Run diagnostics beta div function
echoPlus ""
echoPlus "Do you want to generate beta diversity matrices? (full and rarefied to 1000 reads per sample)"
echoPlus "Note: the output can be directly used to generate ordination graphs or hierarchical dendrograms."
echoPlus "        yes - Run betadiv"
echoPlus "        no  - Skip betadiv"
read BETADIV
echo "$BETADIV" >> ampproc-$STARTTIME.log

# Check that the question answers are script readable.
# note: arg between quotes means it can be nothing without producing error.

if [[ ! "$SINGLEREADS" =~ ^(SR|both|PE)$ ]]
    then
    echoPlus ""
    echoPlus "Single reads / SR+PE: $SINGLEREADS invalid argument."
    echoPlus "Sorry I didn't understand what you wrote. Please also make sure that you have the correct upper/lower case letters."
    echoPlus "You can also run the help function with the option -help or -h."
    echoWithDate "    Exiting script"
    echoPlus ""
    exit 1
fi

if [[ ! "$AMPREGION" =~ ^(V13|V4|ITS|V35)$ ]]
    then
    echoPlus ""
    echoPlus "Amplicon region: $AMPREGION invalid argument."
    echoPlus "Sorry I didn't understand what you wrote. Please also make sure that you have the correct upper/lower case letters."
    echoPlus "You can also run the help function with the option -help or -h."
    echoWithDate "    Exiting script"
    echoPlus ""
    exit 1
fi

if [[ "$REFDATABASE" -lt 1 ]] || [[ "$REFDATABASE" -gt 7 ]]
    then
    echoPlus ""
    echoPlus "Reference database: $REFDATABASE invalid argument."
    echoPlus "Sorry I didn't understand what you wrote. Please make sure that you select the correct database."
    echoPlus "You can also run the help function with the option -help or -h."
    echoWithDate "    Exiting script"
    echoPlus ""
    exit 1
fi

if [[ ! "$MAKETREE" =~ ^(yes|no)$ ]]
    then
    echoPlus ""
    echoPlus "Tree making: $MAKETREE invalid argument."
    echoPlus "Sorry I didn't understand what you wrote. Please also make sure that you have the correct upper/lower case letters."
    echoPlus "You can also run the help function with the option -help or -h."
    echoWithDate "    Exiting script"
    echoPlus ""
    exit 1
fi

if [[ ! "$BETADIV" =~ ^(yes|no)$ ]]
    then
    echoPlus ""
    echoPlus "Betadiversity: $BETADIV invalid argument."
    echoPlus "Sorry I didn't understand what you wrote. Please also make sure that you have the correct upper/lower case letters."
    echoPlus "You can also run the help function with the option -help or -h."
    echoWithDate "    Exiting script"
    echoPlus ""
    exit 1
fi

# Automatically turn on tree building if betadiversity is switched on.
if [ $BETADIV = "yes" ]
   then
   MAKETREE="yes"
fi

# Extract Reference database name and version
Refdatabase_Name_Function

# Write command parameters to log
Run_Time_Params_Function


#########################################################
# DATA PROCESSING
#########################################################


# Finding your samples and copying them to the current directory
# Filter potential phiX contamination
echoPlus ""
echoWithDate "Finding your samples and copying them to the current directory, and filtering potential phiX contamination"
Find_reads_phix_Function
echoWithDate "     Output raw sequences in phix_filtered/"


################
# SINGLE READS
################
  
if [[ $SINGLEREADS =~ ^(SR|both)$ ]]
    then
    # Quality filtering
    Fastqc_singlereads_Function
    echoWithDate "    Output files of QC:" 
    echoPlus "      all.singlereads.nophix.qc.R1.fa"
    echoPlus "      all.singlereads.nophix.qc.R2.fa"
    #date

    # Dereplicate uniques
    Dereplicate_Function all.singlereads.nophix.qc.R1.fa
    mv DEREPout.fa uniques.R1.fa
    Dereplicate_Function all.singlereads.nophix.qc.R2.fa
    mv DEREPout.fa uniques.R2.fa
    echoWithDate "    Output files of derep: uniques.R1.fa and uniques.R2.fa"
    #date
  
#############          
 #   # Prefilter to remove anomalous reads
 #   # Prefiltering at 60% ID not implemented for ITS.
 #   if [ $AMPREGION = "ITS" ]
 #       then
 #           mv uniques.R1.fa prefilt_out.R1.fa
 #           mv uniques.R2.fa prefilt_out.R2.fa
 #       else
 #           # Prefilter bacteria to remove anomalous reads
 #           Prefilter_60pc_Function uniques.R1.fa
 #           mv prefilt_out.fa prefilt_out.R1.fa
 #           Prefilter_60pc_Function uniques.R2.fa
 #           mv prefilt_out.fa prefilt_out.R2.fa
 #           echo "    Output files of prefiltering: prefilt_out.R1.fa and prefilt_out.R2.fa"
 #   fi
 #############
    
    if [[ $ZOTUS =~ ^(otu|both)$ ]]
       then       
       # Cluster OTUs + taxonomy assignment
    #   Cluster_otus_Function prefilt_out.R1.fa
       Cluster_otus_Function uniques.R1.fa
       mv otus.fa otus.R1.tmp
   #    Cluster_otus_Function prefilt_out.R2.fa
       Cluster_otus_Function uniques.R2.fa
       mv otus.fa otus.R2.tmp

      # Prefilter to remove anomalous reads
      # Prefiltering at 60% ID not implemented for ITS.
      if [ $AMPREGION = "ITS" ]
       then
         mv otus.R1.tmp otus.R1.fa
         mv otus.R2.tmp otus.R2.fa
       else
         Prefilter_60pc_Function otus.R1.tmp
         mv prefilt_out.fa otus.R1.fa
         Prefilter_60pc_Function otus.R2.tmp
         mv prefilt_out.fa otus.R2.fa
      fi
       echoWithDate "    Output files of OTU clustering: otus.R1.fa and otus.R2.fa"
           
       Predict_taxonomy_Function otus.R1.fa OTUsR1
       mv sintax_out.txt sintax_out.otus.R1.txt
       Predict_taxonomy_Function otus.R2.fa OTUsR2
       mv sintax_out.txt sintax_out.otus.R2.txt
       echoWithDate "    Output files of OTU taxonomy assignment: sintax_out.otus.R1.txt and sintax_out.otus.R2.txt"

      # Build OTU table
      Make_otutable_Function all.singlereads.nophix.R1.fq otus.R1.fa sintax_out.otus.R1.txt
      mv otutable.txt otutable.R1.txt
      mv otutable_notax.txt otutable_notax.R1.txt
      Make_otutable_Function all.singlereads.nophix.R2.fq otus.R2.fa sintax_out.otus.R2.txt
      mv otutable.txt otutable.R2.txt
      mv otutable_notax.txt otutable_notax.R2.txt
      echoWithDate "    Output file of OTU table: otutable_notax.R1.txt and otutable_notax.R1.txt"
      echoWithDate "    Output file for final otu table: otutable.R1.txt and otutable.R2.txt"

      # Taxonomy reports from SINTAX output
      Taxonomy_reports_Function sintax_out.otus.R1.txt otutable_notax.R1.txt otusR1
      Taxonomy_reports_Function sintax_out.otus.R2.txt otutable_notax.R2.txt otusR2
 
       if [ $MAKETREE = "yes" ]
           then
           MaketreeWrapper_Function otus.R1.fa OTUsR1
           MaketreeWrapper_Function otus.R2.fa OTUsR2
       fi

       if [ $BETADIV = "yes" ]
          then
	  Betadiv_Function otus.R1.fa otutable_notax.R1.txt OTUsR1
          Betadiv_Function otus.R2.fa otutable_notax.R2.txt OTUsR2
       fi

    echoWithDate ""
  fi  

    if [[ $ZOTUS =~ ^(zotu|both)$ ]]   # Run the zotu workflow
        then
        # Cluster zOTUs + taxonomy assignment
#        Unoise3_Function prefilt_out.R1.fa
        Unoise3_Function uniques.R1.fa
        mv zotus.fa zotus.R1.tmp
#        Unoise3_Function prefilt_out.R2.fa
        Unoise3_Function uniques.R2.fa
        mv zotus.fa zotus.R2.tmp

     # Prefilter to remove anomalous reads
     # Prefiltering at 60% ID not implemented for ITS.
     if [ $AMPREGION = "ITS" ]
      then
        mv zotus.R1.tmp zotus.R1.fa
        mv zotus.R2.tmp zotus.R2.fa
      else
        Prefilter_60pc_Function zotus.R1.tmp
        mv prefilt_out.fa zotus.R1.fa
        Prefilter_60pc_Function zotus.R2.tmp
        mv prefilt_out.fa zotus.R2.fa
        rm zotus.R1.tmp zotus.R2.tmp
     fi
        echoWithDate "    Output ZOTU files: zotus.R1.fa and zotus.R2.fa"
                
        Predict_taxonomy_Function zotus.R1.fa ZOTUsR1
        mv sintax_out.txt sintax_out.zotus.R1.txt
        Predict_taxonomy_Function zotus.R2.fa ZOTUsR2
        mv sintax_out.txt sintax_out.zotus.R2.txt
        echoWithDate "    Output ZOTU taxonomy files: sintax_out.zotus.R1.txt and sintax_out.zotus.R2.txt"

        # Build zOTU table
        Make_zotutable_Function all.singlereads.nophix.R1.fq zotus.R1.fa sintax_out.zotus.R1.txt
        mv zotutable.txt zotutable.R1.txt
        mv zotutable_notax.txt zotutable_notax.R1.txt
        Make_zotutable_Function all.singlereads.nophix.R2.fq zotus.R2.fa sintax_out.zotus.R2.txt
        mv zotutable.txt zotutable.R2.txt
        mv zotutable_notax.txt zotutable_notax.R2.txt
    
        echoWithDate "    Output file of zOTU table: zotutable_notax.txt"
        echoWithDate "    Output file for final zOTU table: zotutable.txt"

        Taxonomy_reports_Function sintax_out.zotus.R1.txt zotutable_notax.R1.txt zotusR1
        Taxonomy_reports_Function sintax_out.zotus.R2.txt zotutable_notax.R2.txt zotusR2

        # Align sequences and build trees
        if [ $MAKETREE = "yes" ]
           then
           MaketreeWrapper_Function zotus.R1.fa ZOTUsR1
           MaketreeWrapper_Function zotus.R2.fa ZOTUsR2
        fi

       # Generate beta diversity matrices
       if [ $BETADIV = "yes" ]
          then
	  Betadiv_Function zotus.R1.fa zotutable_notax.R1.txt ZOTUsR1
          Betadiv_Function zotus.R2.fa zotutable_notax.R2.txt ZOTUsR2
       fi

    echoWithDate ""

     fi  
fi

if [ $SINGLEREADS = "SR" ]
    then
    echoPlus ""
    echoPlus "Removing temporary files and directories"
    Cleanup_Function
    echoPlus ""
    echoWithDate "Single read data processing is done. Enjoy."
    echoPlus ""
    exit 0
    
    elif [ $SINGLEREADS = "both" ]
      then
      echoPlus ""
      echoWithDate "Single read data processing is done."
    
fi


################
# PE READS
################

echoPlus ""
echoWithDate "Starting workflow for paired-end read data."

# Merge paired ends
Merge_Function
mv mergeout.fq all.merged.nophix.fq
echoWithDate "    Output file of merging: all.merged.nophix.fq"

# Quality filtering
if [ $AMPREGION = "V13" ]
    then
    Fastqc_Function all.merged.nophix.fq 425
fi

if [ $AMPREGION = "V4" ]
    then
    Fastqc_Function all.merged.nophix.fq 200
fi

if [ $AMPREGION = "ITS" ]
    then
    Fastqc_Function all.merged.nophix.fq 200
fi

if [ $AMPREGION = "V35" ]
    then
    Fastqc_Function all.merged.nophix.fq 400
fi


mv QCout.fa all.merged.nophix.qc.fa
echoWithDate "    Output file of QC: all.merged.nophix.qc.fa"

# Dereplicate to uniques
Dereplicate_Function all.merged.nophix.qc.fa
mv DEREPout.fa uniques.fa
echoWithDate "    Output file of derep: uniques.fa"

########################
## Prefiltering at 60% ID not implemented for ITS.
## Prefiltering at 60% ID for V4 and V13.
#if [ $AMPREGION = "ITS" ]
#    then
#        mv uniques.fa prefilt_out.fa
#    else
#        # Prefilter to remove anomalous reads
#        Prefilter_60pc_Function uniques.fa
#        #mv prefilt_out.fa all.merged.nophix.qc.uniques.prefilt.fa
#        echo "    Output file of prefiltering: prefilt_out.fa"
#fi
#########################

# Cluster OTUs + taxonomy assignment
if [[ $ZOTUS =~ ^(otu|both)$ ]]
  then
  #Cluster_otus_Function prefilt_out.fa
  Cluster_otus_Function uniques.fa
  mv otus.fa otus.tmp

  if [ $AMPREGION = "ITS" ]
    then
      mv otus.tmp otus.fa
    else
      # Prefilter to remove any other anomalous reads
      Prefilter_60pc_Function otus.tmp
      mv prefilt_out.fa otus.fa
  fi
  echoWithDate "    Output file of OTU clustering: otus.fa"

  Predict_taxonomy_Function otus.fa OTUs
  mv sintax_out.txt sintax_out.otus.txt
  echoWithDate "    Output file of taxonomy: sintax_out.otus.txt"
  
  # Build OTU table
  Make_otutable_Function all.merged.nophix.fq otus.fa sintax_out.otus.txt
  echoWithDate "    Output file of OTU table: otutable_notax.txt"
  echoWithDate "    Output file for final otu table: otutable.txt"

  # Taxonomy reports from SINTAX output
  Taxonomy_reports_Function sintax_out.otus.txt otutable_notax.txt otus
  echoWithDate ""

  # Align sequences, build tree
  if [ $MAKETREE = "yes" ]
      then
      MaketreeWrapper_Function otus.fa OTUS
  fi

  # Generate beta diversity matrices that can be fed into Ampvis or R base.
  if [ $BETADIV = "yes" ]
      then
      Betadiv_Function otus.fa otutable_notax.txt OTUS
  fi
fi


# Cluster zOTUs + taxonomy assignment
if [[ $ZOTUS =~ ^(zotu|both)$ ]]
    then
#    Unoise3_Function prefilt_out.fa 
#    #mv zotus.fa zotus.fa
     Unoise3_Function uniques.fa
     mv zotus.fa zotus.tmp

     if [ $AMPREGION = "ITS" ]
       then
         mv zotus.tmp zotus.fa
       else
         # Prefilter to remove any other anomalous reads
         Prefilter_60pc_Function zotus.tmp
         mv prefilt_out.fa zotus.fa
     fi

    echoWithDate "    Output zotu file: zotus.fa"

    Predict_taxonomy_Function zotus.fa ZOTUs
    mv sintax_out.txt sintax_out.zotus.txt
    echoWithDate "    Output file of ZOTU taxonomy files: sintax_out.zotus.txt"

    # Build zOTU table
    Make_zotutable_Function all.merged.nophix.fq zotus.fa sintax_out.zotus.txt
    echoWithDate "    Output file of zOTU table: zotutable_notax.txt"
    echoWithDate "    Output file for final zOTU table: zotutable.txt"

    # Taxonomy reports from SINTAX output
    Taxonomy_reports_Function sintax_out.zotus.txt zotutable_notax.txt zotus
    
    # Align sequences, build tree
    if [ $MAKETREE = "yes" ]
       then
       MaketreeWrapper_Function zotus.fa ZOTUS
       MaketreeWrapper_Function zotus.fa ZOTUS
    fi

   # Generate beta diversity matrices that can be fed into Ampvis or R base.
   if [ $BETADIV = "yes" ]
       then
       Betadiv_Function zotus.fa zotutable_notax.txt ZOTUS
   fi

fi




#########################################################
# TEMPORARY FILE REMOVAL
#########################################################

# Remove temporary files and directories
#echoPlus ""
echoWithDate "Removing temporary files and directories"

Cleanup_Function

#echoPlus ""
echoWithDate "Paired-end read processing is done. Enjoy."
echoPlus ""


