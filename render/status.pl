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

require '../rrd_lastupdate.pm';

my $U_nom_tot = $pack_info{ U_nom } * $pack_info{ n_serial };
my $C_nom_tot = $pack_info{ C_nom } * $pack_info{ n_parallel };

my $title = sprintf "BMS status %s V %s Ah %s %s %dS%dP", 
	$U_nom_tot, $C_nom_tot,
	$pack_info{ cell_tech },
	$pack_info{ cell_type },
	$pack_info{ n_serial }, 
	$pack_info{ n_parallel },
;

# cal our own rrd-last-update impmentation
my %cells_state = rrd_lastupdate ( $rrd_cells );

#============================== start HTML =================================
#
print header();
print start_html(-title => $title);
print h1($title);

# ~~~~~~~~~ debug output ~~~~~~~~~~~~~~~~~~~~~~~
print "<pre>\n";

print Dumper (\%pack_info);
print Dumper ( \@warn_levels , \@warn_colors);

print "\$lastupdate: $cells_state{ lastupdate } \n";
print "\$rrd_ERR: $cells_state{ rrd_errstr } \n";
print "\$lastupdate_hr: $cells_state{ lastupdate_hr } \n";


print Dumper ( \%cells_state );
 

print "</pre>\n";
# ~~~~~~~~ end of debug ~~~~~~~~~~~~~~~~~~~~~~~~~

print end_html();

exit;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

