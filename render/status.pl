#!/usr/bin/perl
#
use strict;
use warnings;

use RRDs;
# use CGI;
use CGI qw/:standard/;
use Data::Dumper::Simple ;

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


# --- [ cells.rrd ] ---------------------------------  
#        OK  (1s)        |  U01 U02 U03   ....  U20 U21 U22
# 2021-01-21 10:11:12     |       2.058 2.074 2.067   ...  2.053 2.089 2.084 
# --- [ pack56.rrd ] ---------------------------------  
#         OK  (1s)        |  Vtot Ah Wh
# 2021-01-21 10:11:12     |       45.724 3.975 0.055 
# --- [ pack57.rrd ] ---------------------------------  
#         OK  (0s)        |  curr mode Vend_c SOC temp1 temp2
# 2021-01-21 10:11:13     |       0 2 2.75 0 15.5 11.2 


print header();
print start_html(-title => $title);
print h1($title);

print "<pre>\n";

print Dumper (\%pack_info);
print Dumper ( \@warn_levels , \@warn_colors);
print "</pre>\n";


print end_html();

