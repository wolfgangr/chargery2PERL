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
my $rrd_p56   = $rrd_dir . 'pack56.rrd';
my $rrd_p57   = $rrd_dir . 'pack57.rrd';

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

my %p56_state = rrd_lastupdate ( $rrd_p56 );
my %p57_state = rrd_lastupdate ( $rrd_p57 );

my %tv ;
for my $tag ( qw (Vtot Ah Wh)) 
 	{ $tv{ $tag } = $p56_state{ ds_last }->[ $p56_state{ds_map}->{ $tag } ] ; }
for my $tag ( qw ( curr mode Vend_c SOC temp1 temp2  )) 
        { $tv{ $tag } = $p57_state{ ds_last }->[ $p57_state{ds_map}->{ $tag } ] ; }



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
print h3($title);

print '<hr><table border=\"1\"><tr>'."\n";
print '<td valign="top"><table><tr>'."\n";

print '<td><table border="1" ><tr>'."\n";
print '<td >soc</td><td width="300">' . $soc_symbol  .  '</td>'."\n";
print '</tr></table></td>'."\n";
print '</tr><tr>';

print '<td><table border="0" cellspacing ="3"  cellpadding="5"  bgcolor="#cccccc"  >'."\n";

# print '<tr><td>&nbsp</td> <td>foo</td><td>bar</td></tr>'."\n";
# print '<tr><td>tralala</td><td>pipapo</td><td>&nbsp</td> </tr>'."\n";
# print '<tr><td>asdf</td><td>&nbsp</td> <td>jklö</td></tr>'."\n";

my $tv_format = '<tr bgcolor="#ffffff" >'
	. '<td align="right" >%s:&nbsp;</td>'
	. '<td align="center" ><b>&nbsp;%s&nbsp;</b></td>' 
	. '<td>&nbsp;%s&nbsp;</td></tr>'
	. "\n";

printf $tv_format, 'Betriebszustand' , '###' , '' ;
printf $tv_format, 'Gesamtspannung' , $tv{Vtot} , 'V' ;
printf $tv_format, 'Strom', , $tv{curr} , 'A' ;
printf $tv_format, 'Ladezustand', , $tv{SOC} , '%' ;
printf $tv_format, 'Ladung', , $tv{Ah} , 'Ah' ;
printf $tv_format, 'Energie', , $tv{Wh} /1000 , 'kWh' ;
printf $tv_format, 'Batterietemperatur', , $tv{temp2}  , '°C' ;
printf $tv_format, 'BMS Temperatur', , $tv{temp1}  , '°C' ;




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


# print Dumper ( \%cells_state );
# print Dumper ( \%p56_state , \%p57_state ); 
print Dumper ( \%tv );

print "</pre>\n";
# ~~~~~~~~ end of debug ~~~~~~~~~~~~~~~~~~~~~~~~~

print end_html();

exit;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

