#!/usr/bin/perl
$cp_dir = $ARGV[0];
$sp_name = $ARGV[1];

open (OID, "$cp_dir/14_ortholog_id/$sp_name") or die "Cannot open file $cp_dir/14_ortholog_id/$sp_name\n";
while ($orth_info = <OID>) {
	($orth_id, $orth_sp, $orth_source) = split (/\t/, $orth_info);
	$orth{$orth_id} = 1;
}

open (PID, "$cp_dir/15_paralog/all") or die "Cannot open file $cp_dir/15_paralog/all\n";
while ($line = <PID>) {
	@para_info = split (/\t/, $line);
	if ($orth{$para_info[0]}) {
		print $line;
	}
}
close (OID);
close (PID);
