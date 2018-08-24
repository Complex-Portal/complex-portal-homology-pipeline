#!/bin/bash
if [[ $# != 1 ]];then
	echo "Usage: $0 ComplexPortalDir"
	exit 1
fi

cp_dir=$1
sp_list=$cp_dir/sp_list_cp

cpu_num=4		# number of CPU used to do each blast
max_target=1	# maximum blast target number
max_hsp=1		# maximum hsp number

blastdb_dir=$cp_dir/08_blastdb
blast_result=$cp_dir/10_blast_result

cat $sp_list |sed 1d |cut -f2 |while read i
do
	test -f $cp_dir/05_uniprot_seq/$i || continue
	protein_file=$cp_dir/05_uniprot_seq/$i
	echo "Blasting proteins of unmapped ids of $i against $i proteome"
	if test -f $blastdb_dir/${i}.phr; then
		blastp -query $protein_file -db $blastdb_dir/$i -out $blast_result/${i}.tblout -outfmt "7 qacc sacc pident" -num_threads $cpu_num -max_target_seqs $max_target -max_hsps $max_hsp
#		blastp -query $protein_file -db $blastdb_dir/$i -out $blast_result/${i}.out -num_threads $cpu_num
	else
		echo "No blastdb for $i"
	fi
done
