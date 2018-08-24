#!/usr/bin/perl
# Lookup where a gene is located on. If it is locate on a chromosome,
# it can be used to find its ortholog(s) or paralog(s) in compara database.
# Otherwise no ortholog or paralog will be found in compara database.
# For example:
#   UniProt Ensembl         Loc
#   A8MTZ0  ENSG00000214413 10
#   A9QM74  ENSG00000185467 7
#   A9QM74  ENSG00000284068 CHR_HG2088_PATCH
# No result will be returned for ENSG00000284068 in compara database.
#
# Input format:
#   A8MTZ0  ENSG00000214413
# Output format:
#   A8MTZ0  ENSG00000214413 10

use strict;
use warnings;
 
use HTTP::Tiny;
use JSON;
 
my $http = HTTP::Tiny->new();
 
my $cp_dir = $ARGV[0];
my $sp_list = "$cp_dir/sp_list_cp";
open (SP, $sp_list);
while (my $line = <SP>) {
	next if ($line =~ m/^#/);
	chomp ($line);
	my @sp_info = split (/\t/, $line);
	my $sp_name = $sp_info[1];
	my $sp_source = $sp_info[2];
	print "Filtering Ensembl IDs for $sp_name ......\n";

	# vertebrates are on ensembl, while other genomes are on ensemblgenomes
	my $server;
	if ($sp_source eq 'Ensembl') {
		$server = 'http://rest.ensembl.org';
	} elsif ($sp_source eq 'EnsemblGenome') {
		$server = 'https://rest.ensemblgenomes.org';
	}

	# read ensembl ids from id mapping file
	my $eid_file = "$cp_dir/03_id_mapping/$sp_name";
	my (@uniprot_id, @ensembl_id, @ensembl_id_q, $tmp, $i);
	$i = 0;
	open (ID, $eid_file);
	while (my $line = <ID>) {
		chomp ($line);
		($uniprot_id[$i], $ensembl_id[$i]) = split (/\t/, $line);
		$ensembl_id_q[$i] = '"'.$ensembl_id[$i].'"';
		$i += 1;
	}
	close (ID);
	my $id_num = $i;

	# remove first line: From To
	shift (@uniprot_id);
	shift (@ensembl_id);
	shift (@ensembl_id_q);

	my $part_num = int ($id_num / 1000);
	for (my $i=0; $i<=$part_num; $i++) {
		# if uniprot id num is larger than 1000, post 1000 each time
		my $start = $i*1000;
		my $stop;
		if ($i<$part_num) {
			$stop = $start+999;
		} else {
			$stop = $id_num-2;
		}
		# concatenate ids, preparing for post
		my $ids = join (', ', @ensembl_id_q[$start..$stop]);
		my $content = '"ids" : ['.$ids.']';

		# lookup id info
		my $ext = "/lookup/id";
		my $response = $http->request('POST', $server.$ext, {
			headers => {
				'Content-type' => 'application/json',
				'Accept' => 'application/json'
			},
			content => '{ '.$content.' }'
		});

		if (! $response->{success}) {
			last;
		}
		#die "Failed!\n" unless $response->{success};

		# print result to file
		my ($j, $mf, $eid, $chr);
		my $ensembl_id_file = "$cp_dir/11_ensembl_id/$sp_name";
		if(length $response->{content}) {
			my $hash = decode_json($response->{content});
			open ($mf, ">>", $ensembl_id_file) or die "Cannot open file $ensembl_id_file\n";
			for ($j=$start; $j<=$stop; $j++) {
				if ($hash->{"$ensembl_id[$j]"}{"id"}) {
					$eid = $hash->{"$ensembl_id[$j]"}{"id"};
				} else {
					$eid = 'NA';
				}
				if ($hash->{"$ensembl_id[$j]"}{"seq_region_name"}) {
					$chr = $hash->{"$ensembl_id[$j]"}{"seq_region_name"};
				} else {
					$chr = 'NA';
				}
				print $mf "$uniprot_id[$j]";
				print $mf "\t";
				print $mf $eid;
				print $mf "\t";
				print $mf $chr;
				print $mf "\n";
			}
			close ($mf);
		}
	}
}
