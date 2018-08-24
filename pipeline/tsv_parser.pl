#!/usr/bin/perl
use warnings;
use strict;
while (my $line = <STDIN>) {
	chomp ($line);
	my ($cp_acc, $proteins) = split (/\t/, $line);
	my @protein = split(/\|/, $proteins);
	foreach my $prot_id (@protein) {
		if ($prot_id =~ m/^([A-Z0-9]{6,})\(\d+\)/) {
			print "$1\t$cp_acc\n"; # normal uniprot id, e.g. P07683
		} elsif ($prot_id =~ m/^([A-Z0-9]{6,})-(PRO_\d+)\(\d+\)/) {
			print "$1\t$cp_acc\t$2\n"; # uniprot id with a chain id, e.g. P07683-PRO_0000001473
		} elsif ($prot_id =~ m/^([A-Z0-9]{6,})-(\d+)\(\d+\)/) {
			print "$1\t$cp_acc\t$2\n"; # uniprot id with a isoform number, e.g. Q15822-2
		}
	}
}
