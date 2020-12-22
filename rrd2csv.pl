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


our $debug =3;

# we need at least a rrd file name and a CF
die "usage $0 db.rrd CF [-s start] [-e end] [-r res] [-a] [-f outfile] [-h] [-x sep] [-d delim] " unless $#ARGV >= 1;
my $rrdfile = shift @ARGV;
my $cf      = shift @ARGV;

getopts('s:e:hx:d:r:af:');

$start  = $opt_s || 'e-1d';
$end    = $opt_e || 'N';
$header = $opt_h;
$sep    = $opt_x;
$delim  = $opt_d;
$align  = $opt_a;
$res    = $opt_r;
$outfile = $opt_f ;

debug_printf (3, "parameter db=%s CF=%s start=%s end=%s resolution=%s align=%d output=%s header=%s sep=%s delim=%s \n",
	$rrdfile, $cf, $start, $end, $res, $align, $outfile, $header , $sep, $delim      );

@paramlist = ($rrdfile, $cf, '-s', $start, '-e', $end);
push @paramlist, '-a' if $align ;
push @paramlist, ('-r', $res ) if $res ; 

debug_printf (3, "%s\n", join ( ' | ', @paramlist));


my ($start,$step,$names,$data) = RRDs::fetch (@paramlist);

# my $startstring = strftime "%c" , $start ; # if ($start ;)

my $dt = DateTime->from_epoch( epoch => $start );
# my $startstring = $dt->ymd('-') . ' ' . $dt->hms(':') ;

debug_printf ( 3, "retrieved, \n start %s step %d, columns %d, rows %d\n\tErr: >%s<\n", 
       	$dt->datetime('_'),
	$step, $#$names, $#$data, RRDs::error);


# ---- go to work ----
# $outfile = '|-' unless  $outfile ;   # this seems to write to STDOUT
if ( $outfile) {
  open (OF , '>' ,   $outfile)  or die "$! \n could not open $outfile for writing"; 
} else {
  # iopen (OF , '|-') or die "$! \n could not access STDOUT for writing";
  *OF = *STDOUT;
}

debug_printf ( 3, "opened output file: %s\n", $outfile ); 

if ($header) { 
   $titleline = my_join ( $delim, $sep, 'time', @$names) ;
   # debug_printf ( 3, "%s\n", $titleline );
   print  OF $titleline . "\n";
   # print  OF " stuff\n";
}

close OF ;

exit ;

#=========================================
# debug_print($level, $content)
sub debug_print {
  $level = shift @_;
  print STDERR @_ if ( $level <= $debug) ;
}

sub debug_printf {
  $level = shift @_;
  printf STDERR  @_ if ( $level <= $debug) ;
}

# my_join : extended join with delim and seperators
# my_join ( delim, sep, @stuff )
sub my_join {
  my $delim = shift  @_ ;
  my $sep   = shift  @_ ;
  # printf ( "%s %s %s\n",  $delim , $sep  , join (":", @_ )) ;
  my $rv  =   return join ( $sep, map { sprintf ( "%s%s%s", $delim, $_ ,$delim) } @_ ) ;
  return $rv ;
  # print $rv . "\n";
  # die "debug"
}
