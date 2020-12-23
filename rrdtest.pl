#!/usr/bin/perl
#
# check lastrun of selected rrd
# optional first param: grace time
# cyclo over rest

my $firstparam = shift @ARGV ;

if ( $firstparam =~ /^\d+$/ ) {
	printf "%s looks like a number\n", $firstparam ;
	$gracetime = $firstparam ;
} else {
	printf "%s is not a number \n", $firstparam ;
	unshift @ARGV , $firstparam;
	$firstparam = undef;
	$gracetime = 60 ;
}

printf "gracetime: %s \n", $gracetime ;
