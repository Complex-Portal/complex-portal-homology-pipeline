#!/bin/bash
start_time=`date`
echo "Started at $start_time."
cp_dir=/homes/zengyan/cp/complex_phylogeny # directory in which all temp data and result are saved

# Work dirs
test -d $cp_dir/00_tsv || mkdir -p $cp_dir/00_tsv
test -d $cp_dir/01_uniprot_complex || mkdir -p $cp_dir/01_uniprot_complex
test -d $cp_dir/02_uniprot_id || mkdir -p $cp_dir/02_uniprot_id
test -d $cp_dir/03_id_mapping || mkdir -p $cp_dir/03_id_mapping
test -d $cp_dir/04_uniprot_id_unmapped || mkdir -p $cp_dir/04_uniprot_id_unmapped
test -d $cp_dir/05_uniprot_seq || mkdir -p $cp_dir/05_uniprot_seq
test -d $cp_dir/06_ensembl_proteome_raw || mkdir -p $cp_dir/06_ensembl_proteome_raw
test -d $cp_dir/07_ensembl_proteome || mkdir -p $cp_dir/07_ensembl_proteome
test -d $cp_dir/08_blastdb || mkdir -p $cp_dir/08_blastdb
test -d $cp_dir/09_ensembl_id_map || mkdir -p $cp_dir/09_ensembl_id_map
test -d $cp_dir/10_blast_result || mkdir -p $cp_dir/10_blast_result
test -d $cp_dir/11_ensembl_id || mkdir -p $cp_dir/11_ensembl_id
#test -d $cp_dir/id_mapping_unmapped || mkdir -p $cp_dir/id_mapping_unmapped
test -d $cp_dir/12_ortholog || mkdir -p $cp_dir/12_ortholog
test -d $cp_dir/13_ortholog_parsed || mkdir -p $cp_dir/13_ortholog_parsed
test -d $cp_dir/14_ortholog_id || mkdir -p $cp_dir/14_ortholog_id
test -d $cp_dir/15_paralog || mkdir -p $cp_dir/15_paralog

# Prepare UniProt IDs from Complex Portal
echo -e "\033[1mDownload tsv files from Complex Portal and collect UniPort IDs:\033[0m"
cat $cp_dir/sp_list_cp |grep -v "^#" |cut -f2 |while read i
do
	test -f $cp_dir/00_tsv/$i && rm -f $cp_dir/00_tsv/$i
	test -f $cp_dir/01_uniprot_complex/$i && rm -f $cp_dir/01_uniprot_complex/$i
	test -f $cp_dir/02_uniprot_id/$i && rm -f $cp_dir/02_uniprot_id/$i
	test -f $cp_dir/03_id_mapping/$i && rm -f $cp_dir/03_id_mapping/$i
	test -f $cp_dir/04_uniprot_id_unmapped/$i && rm -f $cp_dir/04_uniprot_id_unmapped/$i
	test -f $cp_dir/05_uniprot_seq/$i && rm -f $cp_dir/05_uniprot_seq/$i
#	test -f $cp_dir/id_mapping_unmapped/$i && rm -f $cp_dir/id_mapping_unmapped/$i
	test -f $cp_dir/09_ensembl_id_map/$i && rm -f $cp_dir/09_ensembl_id_map/$i
	test -f $cp_dir/11_ensembl_id/$i && rm -f $cp_dir/11_ensembl_id/$i
	test -f $cp_dir/12_ortholog/$i && rm -f $cp_dir/12_ortholog/$i
	test -f $cp_dir/13_ortholog_parsed/$i && rm -f $cp_dir/13_ortholog_parsed/$i
	test -f $cp_dir/14_ortholog_id/$i && rm -f $cp_dir/14_ortholog_id/$i
	test -f $cp_dir/15_paralog/$i && rm -f $cp_dir/15_paralog/$i

	# Downloading tsv files from Complex Portal for each species >00_tsv
	echo -n "Downloading tsv file for $i ...... "
	wget -q -O $cp_dir/00_tsv/$i.tsv "ftp://ftp.ebi.ac.uk/pub/databases/intact/complex/current/complextab/$i.tsv"
	echo "Done. Saved to $cp_dir/00_tsv/$i.tsv"

	# Fetch UniProt IDs from tsv files >uniprot_complex >02_uniprot_id
	echo -n "Processing UniProt ID for $i ...... "
	cat $cp_dir/00_tsv/$i.tsv |sed 1d |cut -f1,5 |perl $cp_dir/pipeline/tsv_parser.pl >tmp1
	num_line=`cat tmp1 |wc -l`
	for j in `seq 1 $num_line`
	do
		echo $i
	done >tmp2
	paste tmp1 tmp2 |uniq >$cp_dir/01_uniprot_complex/$i
	cat $cp_dir/01_uniprot_complex/$i |cut -f1 |sort -u >$cp_dir/02_uniprot_id/$i
	rm -f tmp1 tmp2

	echo "Done. Saved to $cp_dir/02_uniprot_id/$i"
done
echo -e "\033[1mDone\033[0m";
echo

run_dir=$cp_dir/pipeline

# ID mapping >03_id_mapping
echo -e "\033[1mMap UniProt IDs to Ensembl IDs: \033[0m"
$run_dir/id_mapping.pl $cp_dir
echo -e "\033[1mDone\033[0m";
echo

# ID comparing, find ids not mapped in the previous step >04_uniprot_id_unmapped
echo -e "\033[1mCompare mapped Ensembl IDs with original UniProt IDs to find unmapped IDs: \033[0m"
$run_dir/id_comparing.pl $cp_dir
echo -e "\033[1mDone\033[0m";
echo

# Fetch uniprot sequences for unmapped ids >05_uniprot_seq
echo -e "\033[1mDownload uniprot sequences for unmapped ids: \033[0m"
cat $cp_dir/sp_list_cp |sed 1d |cut -f2 |while read i
do
	if test -s $cp_dir/04_uniprot_id_unmapped/$i; then
		echo "Downloading uniprot sequences for $i"
		$run_dir/fetch_uniprot.pl $cp_dir/04_uniprot_id_unmapped/$i >$cp_dir/05_uniprot_seq/$i
	fi
done
echo -e "\033[1mDone\033[0m";
echo

# Download ensembl proteomes, make blastdb and make protein-gene id map >06_ensembl_proteome_raw >07_ensembl_proteome >08_blastdb >09_ensembl_id_map
echo -e "\033[1mDownload ensembl proteomes, make blastdb and make protein-gene id map: \033[0m"
$run_dir/ensembl_genome_to_blastdb.sh $cp_dir
echo -e "\033[1mDone\033[0m";
echo

# Blast, find proteins for unmapped ids in ensembl proteomes >10_blast_result
echo -e "\033[1mBlast to find Ensembl protein ids for unmapped UniProt ids: \033[0m"
$run_dir/batch_blastp.sh $cp_dir
echo -e "\033[1mDone\033[0m";
echo

# Parse Blast result and convert ensembl protein ids to gene ids
echo -e "\033[1mParse Blast result and convert ensembl protein ids to gene ids: \033[0m"
$run_dir/blast_parser.pl $cp_dir
cat $cp_dir/sp_list_cp |sed 1d |cut -f2 |while read i
do
	test -f $cp_dir/04_uniprot_id_unmapped/$i && cat $cp_dir/04_uniprot_id_unmapped/$i >>$cp_dir/03_id_mapping/$i
done
echo -e "\033[1mDone\033[0m";
echo

# ID lookup & filter >11_ensembl_id
echo -e "\033[1mFilter Ensembl IDs: \033[0m"
$run_dir/id_lookup.pl $cp_dir
echo -e "\033[1mDone\033[0m";
echo

# Fetch orthologs from Compara >12_ortholog
echo -e "\033[1mFetch orthologs from Compara: \033[0m"
$run_dir/ortholog.pl $cp_dir
echo -e "\033[1mDone\033[0m";
echo

# Parsing orgholog ids > 13_ortholog_parsed >14_ortholog_id
echo -e "\033[1mParse orthologs: \033[0m"
$run_dir/ortholog_parser.pl $cp_dir
test -f $cp_dir/14_ortholog_id/all && rm -f $cp_dir/14_ortholog_id/all
cat $cp_dir/sp_list_cp |sed 1d |cut -f2 |while read i
do
	# parse and filter result of mus_musculus_x (id started with MGP_)
	cat $cp_dir/13_ortholog_parsed/$i |cut -f3,6 |grep -v "^MGP_" |sort -u >$cp_dir/14_ortholog_id/$i
done
cat $cp_dir/14_ortholog_id/* |sort -u >$cp_dir/14_ortholog_id/all
echo -e "\033[1mDone\033[0m";
echo

# Fetch paralogs from Compara >15_paralog/all
echo -e "\033[1mFetch paralogs from Compara: \033[0m"
test -f $cp_dir/15_paralog/all && rm -f $cp_dir/15_paralog/all
$run_dir/paralog.pl $cp_dir
echo -e "\033[1mDone\033[0m";
echo

# Assign paralogs for each CP species >15_paralog
echo -e "\033[1mAssign paralogs for each CP species: \033[0m"
cat $cp_dir/sp_list_cp |sed 1d |cut -f2 |while read i
do
	$run_dir/paralog_id_assign.pl $cp_dir $i >$cp_dir/15_paralog/$i
done
echo -e "\033[1mDone\033[0m";
echo

stop_time=`date`
echo "Finished at $stop_time."
