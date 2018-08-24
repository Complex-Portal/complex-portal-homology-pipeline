#!/usr/bin/perl
$cp_dir=$ARGV[0];
$sp_list="$cp_dir/sp_list_cp";

open (SP, $sp_list) or die "Cannot open file $sp_list !";
while ($line = <SP>) {
	@sp_info = split (/\t/, $line);
	$sp_name = $sp_info[1];
	if (-e "$cp_dir/10_blast_result/$sp_name.tblout") {
		print "$sp_name:\n";
		open (BF, "$cp_dir/10_blast_result/$sp_name.tblout") or die "Cannot open file $cp_dir/10_blast_result/$sp_name !\n";;
		while ($bf_line = <BF>) {
			next if ($bf_line =~ m/^#/);
			@bf_info = split (/\t/, $bf_line);
			@bf_id_info = split (/\|/, $bf_info[0]);
			$bf_ensembl{$bf_info[1]} = $bf_id_info[1];
		}
		close (BF);
		open (OID, ">$cp_dir/04_uniprot_id_unmapped/$sp_name") or die "Cannot open file $cp_dir/04_uniprot_id_unmapped/$sp_name\n";
		open (ID, "$cp_dir/09_ensembl_id_map/$sp_name") or die "Cannot open file $cp_dir/09_ensembl_id_map/$sp_name\n";
		while ($id_line = <ID>) {
			chomp ($id_line);
			@id_info = split (/\t/, $id_line);
			$id_info[1] =~ s/\.\d+$//;
			if ($bf_ensembl{$id_info[0]}) {
				print (OID "$bf_ensembl{$id_info[0]}\t$id_info[1]\n");
			}
		}
		close (ID);
		close (OID);
	}
}
