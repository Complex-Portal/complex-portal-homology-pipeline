#!/bin/bash
cp_dir=/homes/zengyan/cp
cpx_id=$cp_dir/cpx_id_v215
sp_list=$cp_dir/complex_phylogeny/sp_list_cp_g
cat $cpx_id |while read i
do
	query_num=`cp_protein.sh $i |wc -l`
	cat $sp_list |grep -v "^#" |cut -f5 |while read j
	do
		echo -n "$i	$j	$query_num	"
		cp_protein.sh $i |while read k
		do
			cat $cp_dir/complex_phylogeny/ortholog_parsed_cp/* |grep "^$k	" 
		done |grep "$j" |cut -f1 |sort -u |wc -l
	done
done
