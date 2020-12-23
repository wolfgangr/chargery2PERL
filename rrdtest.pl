#!/usr/bin/perl
#
# check lastrun of selected rrd
# optional first param: grace time
# cycle over rest
# status: initial draft
#
# usage 
# rrdtest.pl [gracetime] foo.rrd [ bar.rrd [ ... ]]
#
# shall report to user and to shell if everything is ok
# i e all rrd last updates are younger than gracetime

our $rrdtool = `which rrdtool   `;
my $firstparam = $ARGV[0] ;

if ( $firstparam   =~ /^\d+$/ ) {
	printf "%s looks like a number\n", $firstparam ;
	$gracetime = shift @ARGV  ;
} else {
	printf "%s is not a number \n", $firstparam ;
	# unshift @ARGV , $firstparam;
	# $firstparam = undef;
	$gracetime = 60 ;
}

printf "gracetime: %s \n", $gracetime ;

my $errcnt = 0;

foreach $arg (@ARGV ) { 
	printf "processing %s ", $arg ;
	my $output =`rrdtool lastupdate $arg ` ;
	print "~~~~~~~~~~~~~~~~~~~~\n";
	print $output;
	# die "looks like $arg is not a nice rrd " unless $output;
	unless ($output) {
		print "\tlooks like $arg is not a nice rrd " ;
		$errcnt ++ ;
		next;
	}

}
print " ~ ~ ~ DONE ~ ~ ~ \n\terrors found: $errcnt\n";
