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
our @warn_col_lo ;
our @warn_col_hi ;

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

# ------------ retrieving --------------------------------------

# cal our own rrd-last-update impmentation
my %cells_state = rrd_lastupdate ( $rrd_cells );
my $n_cells = scalar @{$cells_state{ds_tags}};

my %p56_state = rrd_lastupdate ( $rrd_p56 );
my %p57_state = rrd_lastupdate ( $rrd_p57 );

#------------------------ values retrieved, start evaluation ------------

my %tv ;
for my $tag ( qw (Vtot Ah Wh)) 
 	{ $tv{ $tag } = $p56_state{ ds_last }->[ $p56_state{ds_map}->{ $tag } ] ; }
for my $tag ( qw ( curr mode Vend_c SOC temp1 temp2  )) 
        { $tv{ $tag } = $p57_state{ ds_last }->[ $p57_state{ds_map}->{ $tag } ] ; }


# 00(Discharge) 01 (Charge) 02 (Storage)
my @modes = qw ( Entladen Laden Speichern );
my $mode = $modes[ $tv{ mode } ] ;


#------------------- quantiles visualisation ----------------------
my @cell_volts =  @{$cells_state{ 'ds_last'  }} ;
# max, min, qantiles by sorting indices by value
my @index_by_value = sort { $cell_volts[$a] <=> $cell_volts[$b] } (0 .. $#cell_volts) ;
my $U_c_min = $cell_volts [$index_by_value[0]  ] ;
my $U_c_max = $cell_volts [$index_by_value[-1] ] ;
my $U_c_diff = $U_c_max - $U_c_min ;

# triangles to be rendered with after cell voltage
my @cv_triangles = (('') x scalar @cell_volts) ;
@cv_triangles[$index_by_value[0]] = '&#x25B2;' ; # large triangle up
@cv_triangles[$index_by_value[1]] = '&#x25B4;' ; # small triangle up
@cv_triangles[$index_by_value[2]] = '&#x25B4;' ; # small triangle up
@cv_triangles[$index_by_value[-3]] = '&#x25BE;' ; # small triangle down
@cv_triangles[$index_by_value[-2]] = '&#x25BE;' ; # small triangle down
@cv_triangles[$index_by_value[-1]] = '&#x25BC;' ; # large triangle down

# ----------------- color tagging ---------

# debugger


# color tagger legend

my @color_legend =() ;
for my $i ( 0 .. $#warn_levels ) {
	my $tag = $warn_levels[$i] ;
	# if ($tag eq 'nom') { $tag .= .
	my ( $txt_lo , $txt_hi );
	if ($tag eq 'nom') { 
		$txt_lo = sprintf 'U &lt; %0.2f V', $pack_info{ sprintf 'U_%s' , $tag };
		$txt_hi = sprintf 'U &gt; %0.2f V', $pack_info{ sprintf 'U_%s' , $tag };
	} else {
		$txt_lo = sprintf 'U &lt; %0.2f V', $pack_info{ sprintf 'U_min_%s' , $tag };
		$txt_hi = sprintf 'U &gt; %0.2f V', $pack_info{ sprintf 'U_max_%s' , $tag };
	}

	


	my $lg_hi = sprintf '<tr bgcolor="#%s"><td>%s</td><td>%s</td><td>%s</td></tr>' . "\n" , 
		$warn_col_hi[$i] , $txt_hi  , $tag , 'hi' ;
	my $lg_lo = sprintf '<tr bgcolor="#%s"><td>%s</td><td>%s</td><td>%s</td></tr>' . "\n" , 
		$warn_col_lo[$i] , $txt_lo  , $tag , 'lo' ;
	push    @color_legend, $lg_hi ;
	unshift @color_legend, $lg_lo ;

}

# -----------------------
# tester
# ($colordef, $max/min, $level)   = state_color ( $voltage) 

my %coltester;
for  ( my $U= 1.3 ; $U <=3; $U +=0.05 ) {
	my @rtv = state_color($U );
	$coltester{ sprintf '%0.2f', $U } = \@rtv ;
}	


# hack: add to color legend
for my $ctk ( sort { $a <=> $b  }  keys %coltester) {
 	my ($clr, $min_max, $level) = @{$coltester{ $ctk }} ;
	my $tst = sprintf '<tr bgcolor="#%s"><td>%s</td><td>%s</td><td>%s</td></tr>' . "\n" ,
		$clr  ,$ctk, $level, $min_max ;
	push    @color_legend, $tst ;
}


#-------------------  soc symbol ---------------------------------
# soc symbol is rendered as table in whatever whith 100 vertical bars as <td width="3" height="40"  
# and a gradient from red to green
# TODO  make dependent on real soc once we have such
my $soc_symbol = '<table cellpadding ="0" cellspacing="0" ><tr>' ;

for my $i (0 .. 99) {
	# my $color = # int ( 0x100 * (  ((100-$i) * 2.5 ) + ($i * 2.5 * 0x100)     ) ) ;
	my $green = 0x100 * $i/100 ;
	my $red = 0xff - $green ;
	my $color = sprintf '#%02x%02x%02x', $red , $green , 0 ;
	$soc_symbol .= sprintf ('<td bgcolor="%s" width="3" height="40"  >&nbsp;</td>' , $color  ) ;
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

printf $tv_format, 'Betriebszustand' , 		$mode , '' ;
printf $tv_format, 'Gesamtspannung' , 		$tv{Vtot} , 'V' ;
printf $tv_format, 'Strom',  			$tv{curr} , 'A' ;
printf $tv_format, 'Ladezustand',  		$tv{SOC} , '%' ;
printf $tv_format, 'Ladung',  			$tv{Ah} , 'Ah' ;
printf $tv_format, 'Energie',  			$tv{Wh} /1000 , 'kWh' ;
printf $tv_format, 'Batterietemperatur',  	$tv{temp2}  , '°C' ;
printf $tv_format, 'BMS Temperatur',  		$tv{temp1}  , '°C' ;
printf $tv_format, 'höchste Zellenspannung',    $U_c_max, 'V &#x25BC;' ;
printf $tv_format, 'niedrigste Zellenspannung', $U_c_min, 'V &#x25B2;' ;
# printf $tv_format, 'höchste Zellenspannung', 	$U_c_max, 'V &#x25BC;' ;
printf $tv_format, 'Differenz der Zellenspannungen',  
	(sprintf '%0.3f'   , $U_c_diff ),  'V &#x29D7; ' ;

# print '<font size="-2">';
print join "\n", @color_legend;
# print '</font>';


print '</table></td>'."\n";

print '</tr></table></td>'."\n";


# nested table with the cells bottom up
print '<td ><table  cellpadding="3" cellspacing="5" bgcolor="#dddddd">' ."\n";
for ( my $cell =  $n_cells -1 ; $cell>= 0  ; $cell--   ) {
	printf '<tr><td bgcolor="#aaaaaa" >%s</td><td bgcolor="#cccccc" >%0.3f V</td><td>%s</td></tr>' ."\n" , 
		$cells_state{ds_tags}->[ $cell ],  
		$cells_state{ds_last}->[ $cell ], 
		$cv_triangles[ $cell ] ;
}
print "</table></td>\n";



print "\n</tr></table>\n<hr>";

# ~~~~~~~~~ debug output ~~~~~~~~~~~~~~~~~~~~~~~
print "<pre>\n";

print Dumper (\%pack_info);
print Dumper ( \@warn_levels , \@warn_col_lo , \@warn_col_hi   );

print "\$lastupdate: $cells_state{ lastupdate } \n";
print "\$rrd_ERR: $cells_state{ rrd_errstr } \n";
print "\$lastupdate_hr: $cells_state{ lastupdate_hr } \n";


# print Dumper ( \%cells_state );
# print Dumper ( \%p56_state , \%p57_state ); 
# print Dumper ( \%tv );
# print Dumper ( \@cell_volts );
# print Dumper ( \@index_by_value );
# print Dumper ( \@color_legend );
print Dumper ( \%coltester );
print "</pre>\n";
# ~~~~~~~~ end of debug ~~~~~~~~~~~~~~~~~~~~~~~~~

print end_html();

exit;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# evaluate the voltage limits and map to state color
# ($colordef, $max/min, $level)   = state_color ( $voltage) 
sub state_color {
	my $voltage = shift;
	
	my $hi_lo;
	my $signum;
	my @cols;
	my $level;

	# expand direction from U_nom
	if ($voltage <= $pack_info{ U_nom }) {
		$hi_lo = 'min';
		$signum = -1 ;
		@cols = ( @warn_col_lo );
	} else  {
		$hi_lo = 'max';
		$signum = +1 ;
		@cols = ( @warn_col_hi );
	}

	# ifor my $wl (1 .. $#warn_levels) {
	for ( my $i = $#warn_levels; $i >= 1 ;  $i-- ) {
	# for my $i ( 0.. $#warn_levels ) {
		if ( ($voltage * $signum) > ($pack_info{ 'U_' . $hi_lo . '_' . $warn_levels[ $i ] } * $signum ) ) {
			return ( @cols [ $i ] , $hi_lo , $i ) ;
		
		} else {
			# return ( @cols [ 0 ] , $hi_lo , 0 ) ;
		}
	}
	return ( @cols [ 0 ] , $hi_lo , 0 ) ;
	# return undef;
}
