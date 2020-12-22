#!/usr/bin/perl
#
# extract data from rrd and write csv data
# usage plan: rrd2csv.pl db CF from to header sep delim
#
# idie @ARGV
#
use Getopt::Std;
use  RRDs;
use DateTime;
# use POSIX qw(strftime);


# we need at least a rrd file name and a CF
die "usage $0 db.rrd CF [-s start] [-e end] [-r res] [-a] [-h] [-x sep] [-d delim] " unless $#ARGV >= 1;
my $rrdfile = shift @ARGV;
my $cf      = shift @ARGV;

getopts('s:e:hx:d:r:a');

$start  = $opt_s || 'e-1d';
$end    = $opt_e || 'N';
$header = $opt_h;
$sep    = $opt_x;
$delim  = $opt_d;
$align  = $opt_a;
$res    = $opt_r;

printf STDERR "parameter db=%s CF=%s start=%s end=%s resolution=%s align=%d header=%s sep=%s delim=%s \n",
	$rrdfile, $cf, $start, $end, $res, $align, $header , $sep, $delim      ;

@paramlist = ($rrdfile, $cf, '-s', $start, '-e', $end);
push @paramlist, '-a' if $align ;
push @paramlist, ('-r', $res ) if $res ; 

print STDERR join (@paramlist, ' | '), "\n";

my ($start,$step,$names,$data) = RRDs::fetch (@paramlist);

# my $startstring = strftime "%c" , $start ; # if ($start ;)

my $dt = DateTime->from_epoch( epoch => $start );
# my $startstring = $dt->ymd('-') . ' ' . $dt->hms(':') ;

printf STDERR (" start %s step %d, columns %d, rows %d\n\tErr: >%s<\n", 
       	$dt->datetime('_'),
	$step, $#$names, $#$data, RRDs::error);


