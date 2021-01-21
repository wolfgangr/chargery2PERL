#!/usr/bin/perl
#
use strict;
use warnings;

use RRDs;
# use CGI;
use CGI qw/:standard/;
use utf8;
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
my $n_cells = scalar @{$cells_state{ds_tags}};


my $soc_symbol = '<table cellpadding ="0" cellspacing="0" ><tr>' ;

for my $i (0 .. 99) {
	# my $color = # int ( 0x100 * (  ((100-$i) * 2.5 ) + ($i * 2.5 * 0x100)     ) ) ;
	my $green = 0x100 * $i/100 ;
	my $red = 0xff - $green ;
	my $color = sprintf '#%02x%02x%02x', $red , $green , 0 ;
	$soc_symbol .= sprintf ('<td bgcolor="%s" width="3" height="40"  >&nbsp</td>' , $color  ) ;
}

$soc_symbol .= '</tr></table>';


#============================== start HTML =================================
#
print header();
print start_html(-title => $title);
print h1($title);

print '<hr><table border=\"1\"><tr>'."\n";
print '<td valign="top"><table><tr>'."\n";

print '<td><table border="1" ><tr>'."\n";
print '<td >soc</td><td width="300">' . $soc_symbol  .  '</td>'."\n";
print '</tr></table></td>'."\n";
print '</tr><tr>';

print '<td><table border="1" >'."\n";
print '<tr><td>foo</td><td>bar</td></tr>'."\n";
print '<tr><td>tralala</td><td>pipapo</td></tr>'."\n";
print '<tr><td>asdf</td><td>jklö</td></tr>'."\n";

print '</table></td>'."\n";

print '</tr></table></td>'."\n";


# nested table with the cells bottom up
print '<td ><table  cellpadding="3" cellspacing="5" bgcolor="#dddddd">' ."\n";
for ( my $cell =  $n_cells -1 ; $cell>= 0  ; $cell--   ) {
	printf '<tr><td bgcolor="#aaaaaa" >%s</td><td bgcolor="#cccccc" >%0.3f V</td></tr>' ."\n" , 
		$cells_state{ds_tags}->[ $cell ],  $cells_state{ds_last}->[ $cell ] ;
}
print "</table></td>\n";



print "\n</tr></table>\n<hr>";

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

