# README

Last modified: 8 April 2021

Author: Erika Yashiro, Ph.D.

Script name: AmpProc

Version: 5.1.0.beta2.12.1


########################################

### Contents
   - How to run the help function with usage instructions
   - How to cite the tools used in the workflow
   - Information on reference databases used for taxonomic classification
   - General output file formats
   - Version history


########################################

### To run the help function with usage instructions, type either:

AmpProc5.1 -h

OR

AmpProc5.1 -help

########################################



# For citing the tools used in the workflow:

--------
AmpProc
--------
This is a custom workflow that processes raw amplicon reads. AmpProc acts BOTH as a wrapper for other published software as well as a script that processes and reformats data for downstream applications.  
AmpProc is mainly geared toward amplicon data sequenced on the Illumina sequencing platforms, but I can implement further QC features to handle other technologies if you ask me for them.  
Currently, AmpProc handles mostly ribosomal operon amplicons, and other amplicon types are also now possible to process.  
Author: Erika Yashiro, Ph.D.  
https://github.com/eyashiro/AmpProc

The MiDAS workflow (ASVpipeline.sh) is a collaboration with Kasper Skytte Andersen. The version in AmpProc was adapted from the original version in https://github.com/KasperSkytte/ASV_pipeline

---------------
USEARCH 10 & 11
---------------
version: usearch10.0.240_i86linux64 (used only in one step of Fungi/Eukaryote to generate cluster tree)  
version: usearch11.0.667_i86linux64 (used for all steps of AmpProc)

USEARCH and UCLUST algorithms  
Edgar, R.C. (2010) Search and clustering orders of magnitude faster than BLAST, Bioinformatics 26(19), 2460-2461.  
doi: 10.1093/bioinformatics/btq461

SINTAX algorithm = Taxonomy assignment  
Edgar, R.C. (2016), SINTAX, a simple non-Bayesian taxonomy classifier for 16S and ITS sequences, http://dx.doi.org/10.1101/074161.

UNOISE algorithm = Those who use the unoise3 ZOTU clustering  
Edgar, R.C. (2016), UNOISE2: Improved error-correction for Illumina 16S and ITS amplicon reads.http://dx.doi.org/10.1101/081257

Expected error filtering and paired read merging = Paired-end read merging  
Edgar, R.C. and Flyvbjerg, H (2014) Error filtering, pair assembly and error correction for next-generation sequencing reads  [doi: 10.1093/bioinformatics/btv401].

UPARSE algorithm = OTU clustering  
Edgar, R.C. (2013) UPARSE: Highly accurate OTU sequences from microbial amplicon reads, Nature Methods [Pubmed:23955772,  dx.doi.org/10.1038/nmeth.2604].

--------------------
QIIME 1.9.1
--------------------

QIIME = used for running PYNAST sequence alignment tool used prior to tree-building for prokaryote amplicons, and beta diversity analysis

QIIME allows analysis of high-throughput community sequencing data
J Gregory Caporaso, Justin Kuczynski, Jesse Stombaugh, Kyle Bittinger, Frederic D Bushman, Elizabeth K Costello, Noah Fierer, Antonio Gonzalez Pena, Julia K Goodrich, Jeffrey I Gordon, Gavin A Huttley, Scott T Kelley, Dan Knights, Jeremy E Koenig, Ruth E Ley, Catherine A Lozupone, Daniel McDonald, Brian D Muegge, Meg Pirrung, Jens Reeder, Joel R Sevinsky, Peter J Turnbaugh, William A Walters, Jeremy Widmann, Tanya Yatsunenko, Jesse Zaneveld and Rob Knight; Nature Methods, 2010; doi:10.1038/nmeth.f.303

--------
Fasttree
--------

Fasttree 2.1 = Tree algorithm for V13 and V4, used for Unifrac Beta diversity matrices  
Price, M.N., Dehal, P.S., and Arkin, A.P. (2009) FastTree: Computing Large Minimum-Evolution Trees with Profiles instead of a Distance Matrix. Molecular Biology and Evolution 26:1641-1650, doi:10.1093/molbev/msp077.


########################################


# Information on reference databases used for taxonomic classification

The reference databases linked to AmpProc are updated as needed at each AmpProc version change.

The databases have been slightly reformatted in order to be compatible with USEARCH's sintax function. Notably, you may notice that parentheses were replaced by double underscores, and commas by single underscore. Ambiguous taxon names were also removed (e.g. Ambiguous taxa, unknown, unidentified, uncultured, metagenome).


########################################


# GENERAL OUTPUT FILE FORMATS:


All OTU related files are indicated &ast;otu&ast;.  
All ZOTU related files are indicated &ast;zotu&ast; and &ast;asv&ast;.  
Single read equivalents are indicated &ast;R1&ast; and &ast;R2&ast;.  
Bellow are indicated the output files using OTU as an example. Everything written also applies for zotus.  

Output file of OTU clustering:
 
    otus.fa


OTU table formats 

    OTU table: otutable_notax.txt  
    OTU table with taxonomy information: otutable.txt  
    OTU table normalized to 1000 reads per sample: otutable_notax.norm1000.txt

&ast; The otus.fa and otutable_notax.txt are required for running the a postiori taxonomy assignment function. (Same for their asv/zotu equivalents)


Generating otus taxonomy summary

    Output directory: taxonomy_summary/

    Phlyum summary: otus.phylum_summary.txt
    Class summary: otus.sintax.class_summary.txt
    Order summary: otus.sintax.order_summary.txt
    Family summary: otus.sintax.family_summary.txt
    Genus summary: otus.sintax.genus_summary.txt


Sequence alignment and phylogenetic tree of OTUs

    Output directory: aligned_seqs_OTUS/

    Aligned reads: *_aligned.fasta
    OTU tree: *.tre


Generating beta diversity matrices

    Output files in beta_div_OTUS/

    Weighted UniFrac matrix: *.weighted_unifrac.txt
    Unweighted UniFrac matrix: *.unweighted_unifrac.txt
    Bray Curtis matrix: *.bray_curtis.txt
    Jaccard (abundance-based): *.jaccard.txt
    Jaccard (presence-absence): *.jaccard_binary.txt

