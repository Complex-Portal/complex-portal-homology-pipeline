#!/usr/bin/perl
$cp_dir = $ARGV[0];
$sp_list = "$cp_dir/sp_list_cp_g";
$sp_list_cp = "$cp_dir/sp_list_cp";
open (SP, $sp_list) or die "Cannot open $sp_list\n";
while ($line = <SP>) {
	next if ($line =~ m/^#/);
	chomp ($line);
	@sp_info = split (/\t/, $line);
	$sp_names{$sp_info[1]} = 1;
	$strains{$sp_info[4]} = 1;
}
close (SP);

open (SPC, $sp_list_cp) or die "Cannot open $sp_list_cp\n";
while ($line = <SPC>) {
	next if ($line =~ m/^#/);
	chomp ($line);
	@sp_info_cp = split (/\t/, $line);
	$sp_name_cp = $sp_info_cp[1];
	print "Parsing orthologs for $sp_name_cp ......\n";
	$ortholog_file = "$cp_dir/12_ortholog/$sp_name_cp";
	$parsed_ortholog_file = "$cp_dir/ortholog_parsed_cp/$sp_name_cp";
	open (OR, $ortholog_file) or die "Cannot open $ortholog_file\n";
	open (POR, ">>$parsed_ortholog_file") or die "Cannot open $parsed_ortholog_file\n";
	while ($line2 = <OR>) {
		chomp ($line2);
		@orth_info = split (/\t/, $line2);
		if ($strains{$orth_info[5]}) {
			print (POR "$line2\n");
		}
	}
	close (OR);
	close (POR);
}
