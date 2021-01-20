#!/usr/bin/perl
#
# simple watchdog for rrd files
# to be used in systemd config
#
# https://oss.oetiker.ch/rrdtool/doc/rrdlast.en.html
# rrdtool last filename [--daemon|-d address]
# The last function returns the UNIX timestamp of the most recent update of the RRD.
# RRDs::last returns a single INTEGER representing the last update time.
#
# we don't find a pwerl warrper for lib-sd_notify, so we call console goodies
# 
# systemd-notify 'WATCHDOG=1'
# systemd-notify 'READY=1'

use warnings;
use strict;
use RRDs ;

my $rrddir = '..';  # relative to ./setup, no trailing /
my @watched = qw (  cells.rrd  pack56.rrd  pack57.rrd );
my $gracetime = 20 ; 


my $looptime = 20 ; # sleep between tests - recommended half of WatchdogSec=240 in service file
my $loopt_onfail = 2; # may switch to faster polling to 

my $logstring = "chargery WATCHDOG: %s\n";

# ------- end of config ---------------------------------
#
my $sd_notify_WD  =  "systemd-notify 'WATCHDOG=1'";
my $sd_notify_RDY =  "systemd-notify 'READY=1'";


my $started = 0;
while (1) {
	my $overdue_cnt =0;

	for my $rrd ( @watched ) {
		my $rrdfile = $rrddir . '/'. $rrd;
		my $last = RRDs::last ($rrdfile); 
		my $age = time() - $last;
		if ( $age > $gracetime ) {
			$overdue_cnt++;
			# printf( $logstring, sprintf( " file %s overdue - age = %d ", $rrdfile, $age) )  ;

		}
	}

	# notify - 
	unless ( $overdue_cnt ) { 
		unless ( $started ) {
			printf $logstring,  $sd_notify_RDY ;
			system $sd_notify_RDY;
			$started = 1;	
		}
		# rint "WATCHDOG: $sd_notify_WD \n";
		# printf $logstring, $sd_notify_WD ;
		system  $sd_notify_WD;
		sleep $looptime;
	} else {
		printf( $logstring, sprintf( " %d / %d files overdue ", $overdue_cnt, scalar @watched ) ) ;
		sleep $loopt_onfail;
	}


	# interval
	# sleep $looptime;
}
# time()
