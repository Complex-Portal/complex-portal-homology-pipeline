#!/usr/bin/perl
# Convert UniProt IDs to Ensembl IDs

use strict;
use warnings;
use LWP::UserAgent;

my $base = 'http://www.uniprot.org';
my $tool = 'uploadlists';

my $cp_dir = $ARGV[0];
my $sp_list = "$cp_dir/sp_list_cp";

open (SP, $sp_list) or die "Cannot open file $sp_list, please make sure species info file $sp_list exists!\n";
while (my $line = <SP>) {
	next if ($line =~ m/^#/);
	chomp ($line);
	my @sp_info = split (/\t/, $line);
	my $sp_name = $sp_info[1];
	my $sp_source = $sp_info[2];
	my $uniprot_id_file = "$cp_dir/02_uniprot_id/$sp_name";
	my $mapping_file = "$cp_dir/03_id_mapping/$sp_name";

	print "Mapping UniProt IDs to Ensembl IDs for $sp_name ......\n";

	my @id;
	my $i = 0;
	
	# read UniProt IDs from file
	open (ID, "$uniprot_id_file") or die ("Cannot open file $uniprot_id_file !");
	while (my $line = <ID>) {
			chomp ($line);
		$id[$i] = $line;
		$i++;
	}
	close (ID);

	# cacatenate ids, preparing for post
	my $ids = join (' ', @id);
	my $to_id;

	if ($sp_source eq 'Ensembl') {
		$to_id = 'ENSEMBL_ID';
	} elsif ($sp_source eq 'EnsemblGenome') {
		$to_id = 'ENSEMBLGENOME_ID';
	} else { # source='NA'
		next;
	}

	my $params = {
		from => 'ACC',
		to => "$to_id",
		format => 'tab',
		query => "$ids"
	};

	my $contact = 'zengyan@ebi.ac.uk'; # Please set your email address here to help us debug in case of problems.
	my $agent = LWP::UserAgent->new(agent => "libwww-perl $contact");
	push @{$agent->requests_redirectable}, 'POST';

	my $response = $agent->post("$base/$tool/", $params);

	while (my $wait = $response->header('Retry-After')) {
		print STDERR "Waiting ($wait)...\n";
		sleep $wait;
		$response = $agent->get($response->base);
	}

	open (EID, ">", $mapping_file) or die ("Cannot open file $mapping_file !");
	$response->is_success ?
		print EID $response->content :
		die 'Failed, got ' . $response->status_line . ' for ' . $response->request->uri . "\n";
	close (EID);
	sleep 2;
}
close (SP);
