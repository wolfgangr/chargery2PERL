#!/usr/bin/perl
# create rrd database for overall pack data
# this perl creates a shell script that does the job
# subset values from cmd 56
# 
# so I can modify manually
# and keep it as reference for data structure
#
$target = "create_pack56_rrd.sh";


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

my $cmd = <<'HEAD';
#!/bin/bash
# skript to generate rrd files
# generated by 
HEAD

$cmd .= "# $0 $nl";
$cmd .= "$rrdtool create pack56.rrd --start NOW"; 
$cmd .= sprintf (" --step %d ", $step );
$cmd .=  $nl;

# $cmd .= "DS:curr:GAUGE:10:-500:500 $nl";
# $cmd .= "DS:mode:GAUGE:10:0:2 $nl";
$cmd .= "DS:Vtot:GAUGE:10:0:80 $nl";
# $cmd .= "DS:Vend_c:GAUGE:10:0:4 $nl";
# $cmd .= "DS:SOC:GAUGE:10:0:100 $nl";
$cmd .= "DS:Ah:GAUGE:10:-100:1000 $nl";
$cmd .= "DS:Wh:GAUGE:10:-1000:50000 $nl";
# $cmd .= "DS:temp1:GAUGE:60:-30:100 $nl";
# $cmd .= "DS:temp2:GAUGE:60:-30:100 $nl";

$cmd .= rra ( $hb_sec, $r_sec, 'AVERAGE');
$cmd .= rra ( $hb_min, $r_min, 'MIN', 'MAX', 'AVERAGE');
$cmd .= rra ( $hb_hr,  $r_hr,  'MIN', 'MAX', 'AVERAGE');
$cmd .= rra ( $hb_day,  $r_day,  'MIN', 'MAX', 'AVERAGE');

# print $cmd; 
# print "\n---------    ... executing ....   ----------- \n";
# print `$cmd`;
# print `echo $cmd > $target ; chmod +x $target` ;
open ( TARGET , '>' ,  $target) or die "$! \n could not open $target";
print TARGET $cmd;
close TARGET;
print "$target written\n";

print ` chmod +x $target`;

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



