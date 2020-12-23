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
		# no need to kilroy at STDERR - rrdtool complains there
		print "\tlooks like $arg is not a nice rrd " ;
		$errcnt ++ ;
		next;
	}
	
	my @lines = split ("\n", $output);
	# print "has $#lines lines \n";
	if ( $#lines != 2) {
		# print 
		print STDERR "\tunexpected output format\n$output\n " ;
		$errcnt ++ ;
		next;
	}
	
	# assemble the user friendly output:
	# printf "== %s == | %s\n", $arg, $lines[0]; # db name in top left, col headers follow
	
	unless ( $lines[2] =~ /^(\d{10,}):\s*(.*)$/ ) {
		print STDERR "\tunexpected second line in output\n$lines[2]\n " ;
		$errcnt ++ ;
		next;
	}
	# if succesful 'til here, we have the 2nd line splitted in the regexp backrefs	
	$datetimestr = `date -d \@$1`;
		chomp $datetimestr ;
	$restofline = $2;
	$okstring = 'no clue' ;

	# render the user friendly part
	printf "== %s == | %s\n", $arg, $lines[0]; # db name in top left, col headers follow
	printf "?%s? >%s< >%s< \n", $okstring, $datetimestr, $restofline ;
}
print " ~ ~ ~ DONE ~ ~ ~ \n\terrors found: $errcnt\n";
