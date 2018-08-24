#!/usr/bin/perl
# Convert UniProt IDs to Ensembl IDs

use strict;
use warnings;

my $cp_dir = $ARGV[0];
my $sp_list = "$cp_dir/sp_list_cp";

open (SP, $sp_list) or die "Cannot open file $sp_list, please make sure species info file $sp_list exists!\n";
while (my $line = <SP>) {
	next if ($line =~ m/^#/);
	chomp ($line);
	my @sp_info = split (/\t/, $line);
	my $sp_name = $sp_info[1];
	my $uniprot_id_file = "$cp_dir/02_uniprot_id/$sp_name";
	my $ensembl_id_file = "$cp_dir/03_id_mapping/$sp_name";
	my $output_id_file = "$cp_dir/04_uniprot_id_unmapped/$sp_name";

	print "Mapping UniProt IDs to Ensembl IDs for $sp_name ......\n";

	my (%eids, @eid_info);
	
	# read ensembl ids from file
	if (-e $ensembl_id_file) {
		open (EID, $ensembl_id_file);
		while (my $line = <EID>) {
			@eid_info = split (/\t/, $line);
			$eids{$eid_info[0]} = 1;
		}
		close (EID);
	} else {
		print "File $ensembl_id_file does not exist! This doesn't affect the result.\n";
	}

	# read UniProt IDs from file
	open (OID, ">$output_id_file") or die ("Cannot open file $output_id_file !\n");
	open (UID, "$uniprot_id_file") or die ("Cannot open file $uniprot_id_file !\n");
	while (my $line = <UID>) {
		chomp ($line);
		if (!$eids{$line}) {
			print OID "$line\n";
		}
	}
	close (UID);
	close (OID);
}
close (SP);
