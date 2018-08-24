#!/usr/bin/perl
use strict;
use warnings;

my $cp_dir = $ARGV[0];
my $sp_list = "$cp_dir/sp_list_cp";
 
use JSON;
use HTTP::Tiny;
 
my $http = HTTP::Tiny->new();
 
my ($line, $uniprot_id, $ensembl_id, $chr, $sp_name);

open (SP, $sp_list);
while (my $line = <SP>) {
	next if ($line =~ m/^#/);
	chomp ($line);
	my @sp_info = split (/\t/, $line);
	my $sp_name = $sp_info[1];
	my $sp_source = $sp_info[2];
	my $ortholog_file = "$cp_dir/12_ortholog/$sp_name"; # output ortholog file name
	my $ensembl_id_file = "$cp_dir/11_ensembl_id/$sp_name";
	my $server = '';
	my $compara = '';
	if ($sp_source eq 'Ensembl') {
		$server = 'https://rest.ensembl.org';
		$compara = 'multi';
	} else {
		$server = 'https://rest.ensemblgenomes.org';
		$compara = 'pan_homology';
	}
	
	print "$sp_name:\n";
	open (OF, ">>", $ortholog_file);
	open (ID, $ensembl_id_file);
	my $fail = 0;
	while (my $line = <ID>) {
		my ($uniprot_id, $ensembl_id, $chr) = split (/\t/, $line);
		if ($chr !~ m/^CHR/) {
			print "$line";
			my $try = 0;
			while ($try <= 10) {
				# compara=protists|plants|metazoa|fungi|pan_homology
				my $ext = "/homology/id/$ensembl_id?compara=$compara;content-type=text/xml;format=condensed;type=orthologues";
				my $response = $http->get($server.$ext, {
					headers => { 'Content-type' => 'application/json' }
				});

				if (!$response->{success}) {
					$try += 1;
					print "Try $try\n";
					sleep 2;
					next;
				}
 
				if(length $response->{content}) {
					my $hash = decode_json($response->{content});
					for my $homolog (@{$hash->{'data'}}){
						for my $homolog_each (@{$homolog->{'homologies'}}){
							print OF $uniprot_id."\t";
							print OF $ensembl_id."\t";
							print OF $homolog_each->{'id'}."\t";
							print OF $homolog_each->{'protein_id'}."\t";
							print OF $homolog_each->{'type'}."\t";
							print OF $homolog_each->{'species'}."\t";
							print OF "$sp_source\n";
						}
					}
					last;
				}
			}
		}
		sleep 1;
	}
	close (OF);
	close (ID);
}
close (SP);
