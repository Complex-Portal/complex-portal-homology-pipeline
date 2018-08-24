#!/usr/bin/perl
while ($line = <STDIN>) {
	chomp ($line);
	($cpx_id, $num_participant, $num_participant_present) = split (/\t/, $line);
	if ($num_participant_present/$num_participant >= 0.5) {
		print "$cpx_id\t1\n";
	} else {
		print "$cpx_id\t0\n";
	}
}
