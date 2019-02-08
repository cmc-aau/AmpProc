README

Last modified: 2 November, 2018

Author: Erika Yashiro, Ph.D.

Script name: amplicon.workflow.v5.0.3.beta1.0.sh

Version: 5.0.3.beta1.0



########################################

To run the help function, type either:

bash amplicon.workflow_v5.0.sh -h

OR

bash amplicon.workflow_v5.0.sh -help

########################################

Other aliases available:

bash AmpProc5 -h

OR

bash AmpProc5 -help

########################################



For citing the tools used in the workflow:

-------------------------
amplicon.workflow_v5.0.sh
-------------------------
This is a custom script that processes raw reads. The script acts BOTH as a wrapper for other published software as well as a script that processes and reformats data for downstream applications.
Author: Erika Yashiro, Ph.D.  (ey@bio.aau.dk)

----------
USEARCH 10
----------
(version: usearch10.0.240_i86linux64)

USEARCH and UCLUST algorithms
Edgar,RC (2010) Search and clustering orders of magnitude faster than BLAST, Bioinformatics 26(19), 2460-2461.
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

QIIME = used for running PYNAST sequence alignment tool used prior to tree-building for V13 and V4 amplicons

QIIME allows analysis of high-throughput community sequencing data
J Gregory Caporaso, Justin Kuczynski, Jesse Stombaugh, Kyle Bittinger, Frederic D Bushman, Elizabeth K Costello, Noah Fierer, Antonio Gonzalez Pena, Julia K Goodrich, Jeffrey I Gordon, Gavin A Huttley, Scott T Kelley, Dan Knights, Jeremy E Koenig, Ruth E Ley, Catherine A Lozupone, Daniel McDonald, Brian D Muegge, Meg Pirrung, Jens Reeder, Joel R Sevinsky, Peter J Turnbaugh, William A Walters, Jeremy Widmann, Tanya Yatsunenko, Jesse Zaneveld and Rob Knight; Nature Methods, 2010; doi:10.1038/nmeth.f.303

--------
Fasttree
--------

Fasttree 2.1 = Tree algorithm for V13 and V4, used for Unifrac Beta diversity matrices
Price, M.N., Dehal, P.S., and Arkin, A.P. (2009) FastTree: Computing Large Minimum-Evolution Trees with Profiles instead of a Distance Matrix. Molecular Biology and Evolution 26:1641-1650, doi:10.1093/molbev/msp077.


########################################


GENERAL OUTPUT FILE FORMATS:

All OTU related files are indicated *otu*.
All ZOTU related files are indicated *zotu*.
Single read equivalents are indicated *R1* and *R2*.


Output file of OTU clustering: otus.fa


OTU table formats
    OTU table*: otutable_notax.txt
    OTU table with taxonomy information: otutable.txt
    OTU table normalized to 1000 reads per sample: otutable_notax.norm1000.txt

    * The otus.fa and zotus.fa are required for running 
      the a postiori taxonomy assignment function. Single read variants are also accepted input.


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



########################################

VERSION HISTORY

amplicon.workflow_v5.0.3.beta1.0.sh
Released for user evaluation: 2 November 2018
- Added user environment configuration check to make sure that proper temporary folders are present for the QIIME steps.
- Added alias AmpProc5 as an executable command to run the script.
- Changed default number of threads used to 5 (originally 15) to account for the smaller servers.
- Polished the Help description


amplicon.workflow_v5.0.2.beta1.1.sh
Released for user evaluation: 21 March 2018 
- Fixed the biom convert command, added the format parameter so the command works on Qiime 1.9.0
- Moved the prefilter step to after otu clustering, and lowered stringency, in order to speed up this step.

amplicon.workflow_v5.0.1.sh
Released for user evaluation: 12 March 2018
- Fixed a bug in the taxonomy formatting of the final otutable.txt and zotutable.txt, where missing taxonomy levels in the middle of a taxonomy string were not recognized.
- Added version history information in the README file


amplicon.workflow_v5.0.sh
Released for user evaluation: 7 February 2018
Major upgrade since version 4.3


