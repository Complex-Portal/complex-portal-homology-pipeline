#!/usr/bin/perl
$cpx_info = "/homes/zengyan/cp/cpx_id_sp_v215";
$cpx_stat = "/homes/zengyan/cp/complex_phylogeny/cpx_participant_stat_model_sp";
open (INFO, $cpx_info);
while ($line = <INFO>) {
	chomp ($line);
	@c_info = split (/\t/, $line);
	$sp{$c_info[0]} = $c_info[1];
}
close (INFO);
open (STAT, $cpx_stat);
while ($line = <STAT>) {
	chomp ($line);
	@c_stat = split (/\t/, $line);
#	print "$c_stat[0]\t$c_stat[1]\t$sp{$c_stat[0]}\n";
	if ($c_stat[1] =~ m/$sp{$c_stat[0]}/) {
		print "$c_stat[0]\t$c_stat[1]\t$c_stat[2]\t$c_stat[2]\n";
	} else {
		print "$line\n";
	}
}
close (STAT);
