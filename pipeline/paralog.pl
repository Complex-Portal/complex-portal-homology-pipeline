#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use HTTP::Tiny;
 
my $http = HTTP::Tiny->new();
 
my $cp_dir = $ARGV[0];
my $sp_list = "$cp_dir/sp_list_cp";

my %taxon_id;
open (SP, $sp_list);
while (my $line = <SP>) {
	next if ($line =~ m/^#/);
	chomp ($line);
	my @sp_info = split (/\t/, $line);
	$taxon_id{$sp_info[4]} = $sp_info[0];
}
close (SP);

my $server1 = 'https://rest.ensembl.org';
my $server2 = 'https://rest.ensemblgenomes.org';

my $paralog_file = "$cp_dir/15_paralog/all"; # output paralog file name
my $ortholog_id_file = "$cp_dir/14_ortholog_id/all";

my $fail = 0;
open (OF, ">>", $paralog_file) or die "Cannot open file $paralog_file\n";
open (ID, $ortholog_id_file) or die "Cannot open file $ortholog_id_file\n";
while (my $line = <ID>) {
	chomp ($line);
	my ($ortholog_id, $ortholog_sp) = split (/\t/, $line);
#	if ($ortholog_sp eq 'escherichia_coli_str_k_12_substr_mg1655') {
#		$ortholog_sp = 'escherichia_coli';
#	} elsif ($ortholog_sp =~ m/mus_musculus.*/) {
#		$ortholog_sp = 'mus_musculus'; # mus_musculus_aj...
#	} elsif ($ortholog_sp =~ m/pseudomonas_aeruginosa.*/) {
#		$ortholog_sp = 'pseudomonas_aeruginosa'; # pseudomonas_aeruginosa_mpao1_p2...
#	}
	print "$line\n";
	# compara=protists|plants|metazoa|fungi|pan_homology
	if ($fail != 1) {
		my $ext = "/homology/id/$ortholog_id?compara=multi;content-type=text/xml;format=condensed;type=paralogues;target_taxon=$taxon_id{$ortholog_sp}";
		my $response = $http->get($server1.$ext, {
			headers => { 'Content-type' => 'application/json' }
		});

		if (!$response->{success}) {
			print "Ensembl Failed!\n";
			$fail = 1;
		}

		if(length $response->{content}) {
			my $hash = decode_json($response->{content});
			for my $homolog (@{$hash->{'data'}}){
				for my $homolog_each (@{$homolog->{'homologies'}}){
					print OF $ortholog_id."\t";
					print OF $homolog_each->{'id'}."\t";
					print OF $homolog_each->{'protein_id'}."\t";
					print OF $homolog_each->{'type'}."\t";
					print OF $homolog_each->{'species'}."\t";
					print OF "Ensembl\n";
				}
			}
		}
	}
	if ($fail != 2) {
		# compara=protists|plants|metazoa|fungi|pan_homology
		my $ext = "/homology/id/$ortholog_id?compara=pan_homology;content-type=text/xml;format=condensed;type=paralogues;target_taxon=$taxon_id{$ortholog_sp}";
		my $response = $http->get($server2.$ext, {
			headers => { 'Content-type' => 'application/json' }
	});

		if (!$response->{success}) {
			print "EnsemblGenome Failed!\n";
			$fail = 2;
		}

		if(length $response->{content}) {
			my $hash = decode_json($response->{content});
			for my $homolog (@{$hash->{'data'}}){
				for my $homolog_each (@{$homolog->{'homologies'}}){
					print OF $ortholog_id."\t";
					print OF $homolog_each->{'id'}."\t";
					print OF $homolog_each->{'protein_id'}."\t";
					print OF $homolog_each->{'type'}."\t";
					print OF $homolog_each->{'species'}."\t";
					print OF "EnsemblGenome\n";
				}
			}
		}
	}
}
close (OF);
close (ID);
