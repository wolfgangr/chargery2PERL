#!/usr/bin/perl
#
# extract data from rrd and write csv data

our $usage = <<"EOF_USAGE";
usage: $0 db.rrd CF
  [-s start][-e end][-r res][-a]  [-V valid-rows ]
  [-f outfile][-x sep][-d delim][-t][-T dttag][-H][-M]   [-v #][-h]
EOF_USAGE



our $usage_long = <<"EOF_USAGE_L";
$0:

retrieve data from RRD and output them as CSV to file or STDOUT

$usage 

	for further details, see RRDtool fetch for details
	
	db.rrd	
		rrd file name to retrieve data from

	CF	rrd CF (AVERAGE,MIN,MAX,LAST)

	-s starttime
		transparently forwarded to RRDtool, 
		default NOW - 1 day

	-e endtime
		transparently forwarded to RRDtool,
		default NOW
	
	-r res 
		resolution (seconds per value)
		default is highest available in rrd

	-a align
		adjust starttime to resolution

	-V valid rows
		preselect rows by NaN'niness
		(integer) minimum valid fields i.e not NaN per row
		0 - include all empty (NaN only) rows
		1 - (default ) at least one not-NaN - don't loose any information
		up to num-cols - fine tune information vs data throughput
		negative integers: complement count top down e.g.
		-1 - zero NaN allowed
		-2 - one NaN allowed

		        [-f outfile] [-h] [-H] [-x sep] [-d delim]

	-f output file
		default ist STDOUT if omitted

	-x \;	CSV field separator, default is  ';'

	-d \"	CSV field delimiter, default is ''

	-t	include header tag line

	-T foo	header line time tag, default ist 'time'

	-H	translate unixtime to H_uman readable time
	-M	translate unixtime to M_ySQL timestamps

	-v int	set verbosity level

	-h	print this message

EOF_USAGE_L




use Getopt::Std;
use  RRDs;
use DateTime;
use Data::Dumper  ;
# use POSIX qw(strftime);


our $debug =0;

# we need at least a rrd file name and a CF
# die "$usage" unless $#ARGV >= 1;

my $rrdfile = shift @ARGV;
my $cf      = shift @ARGV;

die "$usage" unless $rrdfile;
die "$usage_long" if ( ! ($cf) ) or $rrdfile eq '-h' or $cf eq '-h' ;

my $retval = getopts('s:e:tT:HMx:d:r:af:HMv:V:h')  ;
die "$usage" unless ($retval) ;

die "$usage_long" if $opt_h  ;

my $start  = $opt_s ; # || 'e-1d';
my $end    = $opt_e ; # || 'now';
my $header = $opt_t;
my $hl_timetag = $opt_T || 'time' ;
my $sep    = $opt_x;
my $delim  = $opt_d;
my $align  = $opt_a;
my $res    = $opt_r;
my $outfile = $opt_f ;
$debug = $opt_v unless $opt_v eq ''; 

my $valid_rows = 1 ;
unless  ($opt_V eq '') {  $valid_rows = $opt_V ;  }


debug_printf (3, "parameter db=%s CF=%s start=%s end=%s resolution=%s align=%d output=%s header=%s sep=%s delim=%s \n",
	$rrdfile, $cf, $start, $end, $res, $align, $outfile, $header , $sep, $delim      );

# @paramlist = ($rrdfile, $cf, '-s', $start, '-e', $end);
@paramlist = ($rrdfile , $cf);

push @paramlist, sprintf ("end='%s'", $end ) if $end  ;
push @paramlist, sprintf ("start='%s'", $start) if $start  ;
push @paramlist, '-a' if $align ;
push @paramlist, ('-r', $res ) if $res ; 
my $paramstring = join ( ' ', @paramlist);

debug_printf (3, "%s\n", join ( ' | ', @paramlist));
# debug_printf (3, "%s\n", $paramstring);


# my ($start,$step,$names,$data) = RRDs::fetch ($paramstring);
my ($start,$step,$names,$data) = RRDs::fetch (@paramlist);


# my $startstring = strftime "%c" , $start ; # if ($start ;)

my $dt = DateTime->from_epoch( epoch => $start );
# my $startstring = $dt->ymd('-') . ' ' . $dt->hms(':') ;

debug_printf ( 3, "retrieved, \n start %s step %d, columns %d, rows %d\n\tErr: >%s<\n", 
       	$dt->datetime('_'),
	$step, $#$names, $#$data, RRDs::error);

if ( $valid_rows < 0 ) { $valid_rows = $#$names + $valid_rows +1 ; }

debug_printf (3, "total cols: %d - lower limit for valid Data points per row : %d \n ", $#$names , $valid_rows );

# ---- go to work ----
#
if ( $outfile) {
  open (OF , '>' ,   $outfile)  or die "$! \n could not open $outfile for writing"; 
} else {
  # way to redirect OF to STDOUT
  *OF = *STDOUT;
}

debug_printf ( 3, "opened output file: %s\n", $outfile ); 

# conditional header
#
if ($header) { 
   my $titleline = my_join ( $delim, $sep, $hl_timetag , @$names) ;
   print  OF $titleline . "\n";
}

# my $rowtime = $start;
# foreach my $datarow ( @$data ) {
for my $rowcnt (0 .. $#$data ) {
   my $datarow = $$data[ $rowcnt ];
   my $rowtime = $start + $rowcnt * $step;
   # check for empty data row
   # foreach (@cell_volts) { $pack_volts += $_ ; }
   my $defcnt = 0 ;
   foreach ( @$datarow )  {  $defcnt++ if defined $_ }

   next unless ($defcnt >= $valid_rows) ;

   # time string format selection
   my $timestring;
   if ( $opt_M ) {
      # mysql datetime format YYYY-MM-DD HH:MM:SS
      my $dt =  DateTime->from_epoch( epoch => $rowtime );
      $timestring =  sprintf ( "%s %s", $dt->ymd('-') , $dt->hms(':') ) ;
   } elsif ( $opt_H ) {
      # human readable datetime e.g. 22.12.2020-05:00:00 , i.e. dd.mm.yyyy-hh:mm:ss
      my $dt =  DateTime->from_epoch( epoch => $rowtime );
      $timestring =  sprintf ( "%s-%s", $dt->dmy('.') , $dt->hms );
   } else {
     $timestring = sprintf "%s" , $rowtime ;
   }

   my $dataline = my_join ( $delim, $sep, $timestring, @$datarow ) ;
   # $rowtime += $step ;
   print  OF $dataline . "\n";
   # print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
   # print Dumper ($datarow );
   # print Dumper ($dataline);
   # die "debug~~~~~~~~~~~~~~~~~~~~~~~~~~~";

} 

# 

close OF if ( $outfile) ;

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
