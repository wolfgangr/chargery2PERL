#!/usr/bin/perl
# create rrd database for battery cell voltages
#
$num_cells = 22;		# Battery size

				# cmp solarlog data, w/ additional spike logger
$step = 5 ;			# 5 s expected update rate

$hb_sec = 10 / $step ;		# 10 s granularity
$r_sec = 86400;			# 10 days

$hb_min = 300 / $step ;		# 5 min granularity
$r_min = 26000 ;		# 3 monts

$hb_hr = 3600 / $step ;		# 1 hr granularity
$r_hr = 10000;			# > 1 yr

$hb_day = 24 * $hb_hr ;		# 24 hr granularity  
$r_day = 22000;			# 6 yrs

$rrdtool =`which rrdtool`;
chomp $rrdtool ;
our $nl = " \\\n";

my $cmd = "$rrdtool create cells.rrd --start NOW"; 
$cmd .= sprintf (" --step %d ", $step );
$cmd .=  $nl;

foreach my $cell(1 .. $num_cells) {
  $cmd .= sprintf ("DS:U%02d" , $cell ) ;
  $cmd .= ":GAUGE:10:0.0:5.0";

  $cmd .=  $nl ;
}


$cmd .= rra ( $hb_sec, $r_sec, 'AVERAGE');
$cmd .= rra ( $hb_min, $r_min, 'MIN', 'MAX', 'AVERAGE');
$cmd .= rra ( $hb_hr,  $r_hr,  'MIN', 'MAX', 'AVERAGE');
$cmd .= rra ( $hb_day,  $r_day,  'MIN', 'MAX', 'AVERAGE');

print $cmd; 
print "\n---------    ... executing ....   ----------- \n";
print `$cmd`;

exit;

# --------------------------
# rra (steps, rows, list-of-CF-tags)
sub rra {
  my $rv="";
  my $s = shift ;
  my $r = shift ;
  foreach my $tag ( @_ ) {
    $rv .= sprintf ("RRA:%s:0.5:%d:%d %s", $tag , $s, $r , $nl );
  }
  return $rv ;
}



