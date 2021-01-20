#!/usr/bin/perl
#
# https://blog-en.openalfa.com/how-to-work-with-binary-data-in-a-perl-script



# my $filename = "test12.raw" ;
my $device ="../dev_chargery";
my $filename =  $device ;

# rrd database locations 
our $num_cells = 22;		# Battery size
my $path_to_rrd = `pwd`;
chomp $path_to_rrd;
$path_to_rrd .= '/' ;
# my $path_to_rrd .= "~/chargery/rrd/";
# my $path_to_rrd = "";
my $rrd_cells  = $path_to_rrd . "cells.rrd" ;
my $rrd_pack56 = $path_to_rrd . "pack56.rrd";
my $rrd_pack57 = $path_to_rrd . "pack57.rrd";

# how to match rrd field structure against hash tags
my $rrd_tpl_cells  = join (":" ,  map { sprintf ( "U%02d" , $_) } (1..$num_cells)  ) ;
# 	U1:U2:U3:...20:21:22

my $rrd_tpl_pack56 = "Vtot:Ah:Wh" ;
my @hash_slice_56 = qw (sum_volts Ah Wh) ;

my $rrd_tpl_pack57 = "curr:mode:Vend_c:SOC:temp1:temp2" ;
my @hash_slice_57 = qw (current charge_mode EOC_volt SOC Temp1 Temp2);

# debug level
# 5 crude code development (data structure details)
# 4 rough development (program flow overview)
# 3 life data report normal run
# 2 life data report exception
# 1 config exception
# 0 no debug by my code
$debug = 2;
$dryrun=0; # set to true to avoid rrd updates

#======================
#

use RRDs ;
use Data::HexDump;
# use String::Dump qw( dump_hex);
# use Data::Dump::OneLine;
use Data::Dumper;

# do this outside in the watchdog 
# system("setstty-RS485.sh");

open DATAIN, $filename
	or die "Error opening binary input file $filename: !$\n";

# set stream to binary mode
binmode DATAIN;

my $data;
my $nbytes;

my $status =0;
my $fieldpos =0;
my $crc = 0;
my $recentcmd =0 ;
my $now ;

while ($nbytes = read DATAIN, $data, 1) {

  $byte = ord ($data);
  $hex = sprintf ("%02x", $byte);
  debug_printf (6, " (%s <- %d) ", $hex  , $byte );

  # update field counter, crc, recent command status, 
  unless ( $fieldpos )  { 
    $crc = 0; 
    $recentcmd =0 ;
  }
  $fieldpos++;
  $crc = ($crc + $byte) % 0x100 ;
 
  debug_printf (6, "\n (%s <- %02x -# %05x) ", $hex  , $byte , $crc); 

  debug_print (5, "\n") if ($fieldpos == 1);

  if ( $fieldpos == 4 ) {
    # read data string
    $numdbytes = $byte - 4 ; 
    $nbytes = read DATAIN, $data, $numdbytes ;
    if ($nbytes != $numdbytes ) {
      debug_printf (2, "mismatch reading data - want:%d, got: %d \n", $numdbytes , $nbytes);
      $fieldpos = 0;
      next;
    } 
    # lets hope we got our data in $data
    debug_printf (5, " - %d bytes of raw data: ", $nbytes );
    my @datarray= map (ord, split (undef, $data)); 
    # my own hexdump
    debug_hexdump ( 3, \@datarray );
    debug_print (3, "\n");

    # crc check
    $chksum = pop (@datarray);
    $crc = crc_check ($crc, \@datarray );
    debug_printf (3, "checksum: %02x , cmp %02x ", $chksum, $crc);
    if ( $chksum != $crc ) {
      debug_printf (2, "\nchecksum error: %02x != %02x \n", $chksum, $crc);
      $fieldpos =0;
      next;
    } 

# ------------- data processing --------------
    my $ERR=0;
    if ( $recentcmd == 0x57 ) {
      debug_printf (4, "\n\tcalling command processor for %02x \n\t",  $recentcmd ) ;
      my $res = do_57 ( @datarray ); 
      debug_print ( 5,  Dumper ($res ));

      # assembling rrd data
      debug_printf ( 5, "RRD params %s - %s \n" , $rrd_pack57 , $rrd_tpl_pack57 );
      my $update_data =  join (':', $now, (@{$res}{@hash_slice_57} ));
      debug_printf ( 3, "RRD data %s\n", $update_data );

      # --skip-past-updates gracefully allows multi updates per second 
      RRDs::update ($rrd_pack57, '--skip-past-updates' , '--template', $rrd_tpl_pack57, $update_data ) unless $dryrun ;
      # debug_print ( 2, "ERROR while updating mydemo.rrd: $ERR\n" ) if $ERR = RRDs::error ;
      # debug_rrd ($level1, $level2, $ERR )
      debug_rrd (2,3, RRDs::error );

    } elsif ( $recentcmd == 0x56 ) {
      debug_printf (4, "\n\tcalling command processor for %02x ",  $recentcmd ) ;
      my $res = do_56 ( @datarray );
      debug_print ( 5,  Dumper ($res ));

      # assemble update data for pack part
      debug_printf ( 5, "RRD params %s - %s \n" , $rrd_pack56 , $rrd_tpl_pack56 );

      my $update_data =  join (':', $now, (@{$res}{@hash_slice_56} ));
      debug_printf ( 3, "RRD data %s\n", $update_data );

      RRDs::update ($rrd_pack56, '--template', $rrd_tpl_pack56, $update_data ) unless $dryrun ;
      # debug_print ( 2, "ERROR while updating mydemo.rrd: $ERR\n" ) if $ERR=RRDs::error ;
      debug_rrd (2,3, RRDs::error );

      # assemble update data for cell part
      debug_printf ( 5, "RRD params %s - %s \n" , $rrd_cells , $rrd_tpl_cells );
      
      my $update_data =  join (':', $now, splice ( @{$res->{'cell_volts'}} , 0, $num_cells ) );
      debug_printf ( 3, "RRD data %s\n", $update_data );

      RRDs::update ($rrd_cells, '--template', $rrd_tpl_cells , $update_data ) unless $dryrun ;
      # debug_print ( 2, "ERROR while updating mydemo.rrd: $ERR\n" ) if $ERR=RRDs::error ;
      debug_rrd (2,3, RRDs::error );


# die ("=========== DEBUG stop ============="); # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 



    } elsif ( $recentcmd == 0x58 ) {
      debug_printf (3, "command processor for %02x not yet implemented",  $recentcmd ) ;
      my $res = do_58 ( @datarray );
      debug_print ( 3,  Dumper ($res ));

    }
      else  {
      debug_printf (2, "unknown command %02x - check manual, version, whatever...",  $recentcmd ) ;
    }
# ---------- end processing ---------------

    $fieldpos =0;
    next;
  }

  # check syntax cascade
  if  ($byte == 0x24) { 
    if ( ($fieldpos ==1) or ($fieldpos ==2 ) ) {
      debug_print (5, "'"); 
    } else {
      debug_printf (2, "x24-garbage %s at pos %d\n", $hex, $fieldpos) ;
      $fieldpos = 0;
    }
  } elsif ( ( $byte == 0x56 ) or  ( $byte == 0x57 ) or ( $byte == 0x58) ) {
    if  ($fieldpos ==3 ) {
      # memorize state for further processing
      $recentcmd = $byte;
      $now = time ;
      debug_print (5, "'");
    } else {
      debug_printf (2, "x5X-garbage %s at pos %d\n", $hex, $fieldpos) ;
      $fieldpos = 0;
    }

  } elsif (($fieldpos == 1) and ( $byte == 0x68 ) ) {
    # separator 68 3a 3a 33 0d 0a  aka "h::3\cr\lf"
    $nbytes = read DATAIN, $data, 5;
    if ($debug >= 2) {
      if ($data =~ m/(::3)/) {
	 debug_printf (3, "spacer %c%s skipped\n", $byte, $1) ;
      } else {
        debug_printf (2, "unknown spacer %c.%s\n", $byte, $data)  ;	
      }
    }
    $fieldpos = 0;

  } elsif ($fieldpos <= 3) {
    debug_printf (2, "xXX-garbage %s at pos %d\n", $hex, $fieldpos) ;
    $fieldpos = 0;

  } else {
    # data field still to recognize
    # debug_print (5, " %s", $hex);
    debug_print (5, " :");
  }
  debug_printf (5, "%s", $hex);

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  


}


close DATAIN or die "Eror closing $filename $!\n";

print "\n\n    ==================== regular END ===============\n\n";
exit;


#================================================================================


# debug_print($level, $content)
sub debug_print {
  $level = shift @_;
  print STDERR @_ if ( $level <= $debug) ;
}

sub debug_printf {
  $level = shift @_;
  printf STDERR  @_ if ( $level <= $debug) ;
}

# debug_rrd ($level1, $level2, $ERR ) 
#  level1 : at least to report anything, but ....
#  level2 ... report even double update times
#
sub debug_rrd {
  ($level1, $level2, $ERR) = @_ ;
  return unless ($ERR);
  return if ($debug < $level1);
  my $fiter = '(illegal attempt to update using time )'
  	. '(\d{10,})'
	. '( when last update time is )'
	. '(\d{10,})'
	. ' (\(minimum one second step\))'  
  ;
  return if ( ($ERR =~ /$filter/) and ( $debug < $level2)) ; 
  debug_printf ($level2, "ERROR while updating : %s\n", $ERR);
  # printf ("debug_rrd called: %d - %d - %s\n" , $level1, $level2, $ERR); 
  # printf ("match %s\n %s%s%s%s%s\n", $ERR =~ /$filter/, $0, $1, $2, $3, $4);
  # die (" *********** debug ********");
}

# hexdump, pass array by ref
sub debug_hexdump {
    $level = shift @_;
    return unless ( $level <= $debug) ;
    $ary = shift @_;
    foreach my $x ( @$ary ) {
      printf STDERR  ( " %02x", $x );
    }
}

# crc_check ( $crcold, \@data )
# data is an array of bytes as numbers
sub crc_check {
   my $crc = shift @_;
   $ary = shift @_;
   foreach my $x ( @$ary ) {
           my $oldcrc = $crc;
           $crc = ($crc + $x ) % 0x100 ;
    }
    return $crc;
}

# --------- command processors ------------------

# helpers
# little_endian (@data) - data as byte numbers - return total number
sub little_endian {
  my $res = 0;
  foreach my $byte ( @_ ) {
    $res *= 0x100;
    $res += $byte; 
  }
  return $res;
}

# same in reverse
sub big_endian {
  my $res = 0;
  foreach my $byte ( reverse( @_) ) {
    $res *= 0x100;
    $res += $byte;
  }
  return $res;
}



# do_57 (@data) - crc already stripped
sub do_57 {
  # check for correct data lenght 
  my $parlen = $#_ +1 ;
  return undef unless $parlen  == 10 ;
  
  # the cumbersome part - see def of log stream
  my $EOC_volt = little_endian( splice (@_, 0,2)) / 1000;
  my $mode = shift @_;
  my $current = little_endian( splice (@_, 0,2)) / 10; 
  my $t1 = little_endian( splice (@_, 0,2))  / 10;
  my $t2 = little_endian( splice (@_, 0,2))  / 10;
  my $SOC= shift @_;

  # maybe it's a good idea to keep structure upon retval?
  my %res ; #  = {};
  $res{'EOC_volt'} = $EOC_volt ;
  $res{'charge_mode'} = $mode  ;
  $res{'current'} =  $current ;
  $res{'Temp1'} = $t1 ;
  $res{'Temp2'} = $t2 ;
  $res{'SOC'} = $SOC ;
  $res{'num_param'} = $parlen ;

  return \%res ;
}

# do_56 (@data) - crc already stripped
sub do_56 {
  # we need a trail of 3x4 long fields, at least one cell -> 14 fields
  my $parlen = $#_ +1 ;
  return undef unless $parlen >= 14 ;

  # remove the last 8 bytes for fixed vars, leaving the rest for per cell voltages
  # ... we always have 24 voltages
  my @tail12 = splice (@_, -8) ;

  # process the tail, we are not sure about the association of the extra field
  my $Wh = big_endian( splice (@tail12 , 0 , 4 ) ) / 1000 ;
  my $Ah = big_endian( splice (@tail12 , 0 , 4 ) ) / 1000 ;
  # my $unused = big_endian( splice (@tail12 , 0 , 4 ) ) / 1000 ;
 
  # the rest are per cell voltage readings
  my @cell_volts = () ;
  while ( $#_ > 0) { 
    push ( @cell_volts , little_endian( splice (@_, 0,2))  / 1000 );
  }	  

  # collect the findings
  my %res ;
  $res{'num_param'} = $parlen ;
  $res{'Wh'} = $Wh ;
  $res{'Ah'} = $Ah ;
  # $res{'gww???'} = $dontknow_maybe ; 
  $res{'cell_volts'} = \@cell_volts ; 

  # we keep a sum of all cells as well
  my $pack_volts = 0 ;
  foreach (@cell_volts) { $pack_volts += $_ ; }
  $res{'sum_volts'} = $pack_volts;

  return \%res ;

}
  
# do_58 (@data) - crc already stripped
sub do_58 {
  # still to be tested - no data yet
  my $parlen = $#_ +1 ;
  return undef unless $parlen >= 5 ;

  my $mode = shift @_;
  my $current = little_endian( splice (@_, 0,2)) / 10; 

  # the rest are per cell I_nternal R_esistance readings
  my @cell_IR = () ;
  while ( $#_ > 0) { 
    push ( @cell_IR , little_endian( splice (@_, 0,2))  / 10 );
  }	 

  # collect the findings
  my %res ;
  $res{'num_param'} = $parlen ;
  $res{'charge_mode'} = $mode  ;
  $res{'current'} =  $current ;
  $res{'cell_IRs'} = \@cell_IR ; 

  return \%res ;
}
