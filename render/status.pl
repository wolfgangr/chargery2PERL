#!/usr/bin/perl
#
use strict;
use warnings;

use RRDs;
# use CGI;
use CGI qw/:standard/;
use Data::Dumper::Simple ;
use Time::Piece;


# cells.rrd  pack56.rrd  pack57.rrd
my $rrd_dir = '../';
my $rrd_cells = $rrd_dir . 'cells.rrd'; 


# reference data from cell data sheet
our %pack_info;
our @warn_levels  ;
our @warn_colors ;
require '../BMS-pack-info.pm';

my $U_nom_tot = $pack_info{ U_nom } * $pack_info{ n_serial };
my $C_nom_tot = $pack_info{ C_nom } * $pack_info{ n_parallel };

my $title = sprintf "BMS status %s V %s Ah %s %s %dS%dP", 
	$U_nom_tot, $C_nom_tot,
	$pack_info{ cell_tech },
	$pack_info{ cell_type },
	$pack_info{ n_serial }, 
	$pack_info{ n_parallel },
;



my $lastupdate = RRDs::last ( $rrd_cells );
my $rrd_ERR=RRDs::error ; #  || '' ;
my $lastupdate_obj = Time::Piece->new($lastupdate);
my $lastupdate_hr = $lastupdate_obj->datetime ;

# my $cellstate = RRDs::lastupdate ( $rrd_cells );

my %cells_state = rrd_lastupdate ( $rrd_cells );

print header();
print start_html(-title => $title);
print h1($title);

print "<pre>\n";

print Dumper (\%pack_info);
print Dumper ( \@warn_levels , \@warn_colors);

print "\$lastupdate $lastupdate\n";
printf "\$rrd_ERR %s \n" , ($rrd_ERR || '-')  ;
print "\$lastupdate_hr, $lastupdate_hr\n";

print Dumper ( \%cells_state );
 

print "</pre>\n";


print end_html();

exit;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# implements rrdtest / rrdtool lastupdate functionality
# --- [ cells.rrd ] ---------------------------------
#        OK  (1s)        |  U01 U02 U03   ....  U20 U21 U22
# 2021-01-21 10:11:12     |       2.058 2.074 2.067   ...  2.053 2.089 2.084
# --- [ pack56.rrd ] ---------------------------------
#         OK  (1s)        |  Vtot Ah Wh
# 2021-01-21 10:11:12     |       45.724 3.975 0.055
# --- [ pack57.rrd ] ---------------------------------
#         OK  (0s)        |  curr mode Vend_c SOC temp1 temp2
# 2021-01-21 10:11:13     |       0 2 2.75 0 15.5 11.2
# returns a status hash
#
# %rrdstatus = rrd_lastupdate ( $rrdfile, [ $gracetime ]) 
sub rrd_lastupdate {
	my $rrdfile = shift ;
	my $gracetime = shift || 60 ;

	my %rvh = ( rrdfile => $rrdfile , gracetime => $gracetime );

	my $now = $rvh{testtime} =  time();
	my $lastupdate = $rvh{lastupdate} = RRDs::last ( $rrdfile );
	if (defined ($rvh{'rrd_err' } =  RRDs::error) ) {
		$rvh{'rrd_errstr' } = $rvh{'rrd_err' };
		return %rvh ;
	}  
			
	my $lastupdate_obj = Time::Piece->new($lastupdate);
	my $now_obj = Time::Piece->new($now);
	$rvh{testime_hr} = $now_obj->date . ' - ' .  $now_obj->time ;
	$rvh{lastupdate_hr} = $lastupdate_obj->date . ' - ' .  $lastupdate_obj->time ;	

	$rvh{OK} = ( ($rvh{passed} = $now - $lastupdate ) <= $gracetime );  

	#my $lastupdate_obj = Time::Piece->new($lastupdate);
	#my $lastupdate_hr = $lastupdate_obj->datetime ;
	
	$rvh{'rrd_errstr' } ='-' ;
	return %rvh ;
		
}


