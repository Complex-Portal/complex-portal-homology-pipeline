#/bin/bash
if [[ $# != 1 ]]
then
	echo "Usage: $0 ComplexPortalDir"
	exit 1
fi
cp_dir=$1
sp_list=$cp_dir/sp_list_cp

test -d $cp_dir/06_ensembl_proteome_raw || mkdir $cp_dir/06_ensembl_proteome_raw
test -d $cp_dir/07_ensembl_proteome || mkdir $cp_dir/07_ensembl_proteome
test -d $cp_dir/08_blastdb || mkdir $cp_dir/08_blastdb
test -d $cp_dir/09_ensembl_id_map || mkdir $cp_dir/09_ensembl_id_map

cat $sp_list |grep -v "^#" |while read i
do
	sp_name=`echo $i |cut -d' ' -f2`
	source=`echo $i |cut -d' ' -f3`
	domain=`echo $i |cut -d' ' -f4`

	echo "$sp_name:"
	echo "Downloading proteome from $domain ......"
	if [[ $domain == 'bacteria' ]]
	then
		taxid=`echo $i |cut -d' ' -f1`
		test -f bac_info.txt || wget -q -O bac_info.txt "ftp://ftp.ensemblgenomes.org/pub/current/bacteria/species_EnsemblBacteria.txt"
		bac_name=`grep "	$taxid	" bac_info.txt |sed -n 1p |cut -f2`
		bac_collection=`grep "	$taxid	" bac_info.txt |sed -n 1p |cut -f13 |cut -d'_' -f2`
		url=`wget -O - -q "ftp://ftp.ensemblgenomes.org/pub/current/bacteria/fasta/bacteria_${bac_collection}_collection/$bac_name/pep/" |grep "pep.all.fa.gz" |cut -d'"' -f2`
	elif [[ $domain == 'plants' ]]
	then
		url=`wget -O - -q "ftp://ftp.ensemblgenomes.org/pub/current/plants/fasta/$sp_name/pep/" |grep "pep.all.fa.gz" |cut -d'"' -f2`
	elif [[ $domain == 'fungi' ]]
	then
		url=`wget -O - -q "ftp://ftp.ensemblgenomes.org/pub/current/fungi/fasta/$sp_name/pep/" |grep "pep.all.fa.gz" |cut -d'"' -f2`
	else
		url=`wget -O - -q "ftp://ftp.ensembl.org/pub/current_fasta/$sp_name/pep/" |grep "pep.all.fa.gz" |cut -d'"' -f2`
	fi
	file_name=`basename $url`
	test -n $url && wget -q -O $cp_dir/06_ensembl_proteome_raw/$file_name $url
	test -f $cp_dir/06_ensembl_proteome_raw/$file_name && zcat $cp_dir/06_ensembl_proteome_raw/$file_name >$cp_dir/07_ensembl_proteome/$sp_name
	echo "Making blastdb ......"
	test -f $cp_dir/07_ensembl_proteome/$sp_name && makeblastdb -in $cp_dir/07_ensembl_proteome/$sp_name -out $cp_dir/08_blastdb/$sp_name -dbtype prot -parse_seqids >/dev/null
	echo "Making protein and gene id map ......"
	test -f $cp_dir/07_ensembl_proteome/$sp_name && cat $cp_dir/07_ensembl_proteome/$sp_name |grep '>' |cut -b2- |cut -d' ' -f1,4 |perl -npe 's/ gene:/\t/' >$cp_dir/09_ensembl_id_map/$sp_name
	echo
done
rm -f bac_info.txt
