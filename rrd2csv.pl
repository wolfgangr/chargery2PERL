#!/usr/bin/perl
#
# extract data from rrd and write csv data
# usage plan: rrd2csv.pl db CF from to header sep delim
#
# idie @ARGV
#
use Getopt::Std;

# we need at least a rrd file name and a CF
die "usage $0 db.rrd CF [-s start] [-e end] [-h] [-x sep] [-d delim] " unless $#ARGV >= 1;
my $rrdfile = shift @ARGV;
my $cf      = shift @ARGV;

getopts('s:e:hx:d:');

$start  = $opt_s || 'e-1d';
$end    = $opt_e || 'N';
$header = $opt_h;
$sep    = $opt_x;
$delim  = $opt_d;

printf STDERR "parameter db=%s CF=%s start=%s end=%s header=%s sep=%s delim=%s \n",
	$rrdfile, $cf, $start, $end, $header , $sep, $delim      ;
