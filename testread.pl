#!/usr/bin/perl
#
# https://blog-en.openalfa.com/how-to-work-with-binary-data-in-a-perl-script



my $filename = "test12.raw" ;

# $debug = 6;
#======================
#

use Data::HexDump;
# use String::Dump qw( dump_hex);
# use Data::Dump::OneLine;
use Data::Dumper;


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
$debug = 5;

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
      debug_printf (5, "mismatch reading data - want:%d, got: %d \n", $numdbytes , $nbytes);
      $fieldpos = 0;
      next;
    } 
    # lets hope we got our data in $data
    # debug_printf (5, " - %d bytes of raw data: \n%s", $nbytes, HexDump $data);
    debug_printf (5, " - %d bytes of raw data: ", $nbytes );
    my @datarray= map (ord, split (undef, $data)); 
    # my own hexdump
    # print Dumper ( @data, 1,2,3) ;
    debug_hexdump ( 4, \@datarray );
    debug_print (4, "\n");
    # crc check
    $chksum = pop (@datarray);
    $crc = crc_check ($crc, \@datarray );
    debug_printf (5, "checksum: %02x , cmp %02x ", $chksum, $crc);
    if ( $chksum != $crc ) {
      debug_printf (3, "\nchecksum error: %02x != %02x \n", $chksum, $crc);
      $fieldpos =0;
      next;
    } 

    # data processing
    #------ end processing

    if ( $recentcmd == 0x57 ) {
      debug_printf (3, "\n\tcalling command processor for %02x ",  $recentcmd ) ;
      my $res = do_57 ( @datarray ); 
      debug_print ( 2,  Dumper ($res ));
    } elsif ( $recentcmd == 0x56 ) {
      debug_printf (3, "\n\tcalling command processor for %02x ",  $recentcmd ) ;
      my $res = do_56 ( @datarray );
      debug_print ( 2,  Dumper ($res ));

    } elsif ( $recentcmd == 0x58 ) {
      debug_printf (1, "command processor for %02x not yet implemented",  $recentcmd ) ;
      my $res = do_58 ( @datarray );
      debug_print ( 2,  Dumper ($res ));

    }
      else  {
      debug_printf (1, "unknown command %02x - check manual, version, whatever...",  $recentcmd ) ;
    }

    $fieldpos =0;
    next;
  }

  # check syntax cascade
  if  ($byte == 0x24) { 
    if ( ($fieldpos ==1) or ($fieldpos ==2 ) ) {
      debug_print (5, "'"); 
    } else {
      debug_printf (5, "x24-garbage %s at pos %d\n", $hex, $fieldpos) ;
      $fieldpos = 0;
    }
  } elsif ( ( $byte == 0x56 ) or  ( $byte == 0x57 ) or ( $byte == 0x58) ) {
    if  ($fieldpos ==3 ) {
      # memorize state for further processing
      $recentcmd = $byte;
      debug_print (5, "'");
    } else {
      debug_printf (5, "x5X-garbage %s at pos %d\n", $hex, $fieldpos) ;
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
    debug_printf (5, "xXX-garbage %s at pos %d\n", $hex, $fieldpos) ;
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


#============================================
# debug_print($level, $content)
sub debug_print {
  $level = shift @_;
  print STDERR @_ if ( $level <= $debug) ;
}

sub debug_printf {
  $level = shift @_;
  # $formt
  printf STDERR  @_ if ( $level <= $debug) ;
}

# hexdump, pass array by ref
sub debug_hexdump {
    # print Dumper ( @_, 1,2,3) ; 
    $level = shift @_;
    return unless ( $level <= $debug) ;
    $ary = shift @_;
    # print Dumper ( @$ary ) ;

    foreach my $x ( @$ary ) {
      printf STDERR  ( " %02x", $x );
    }
    # print "--\n";
    # die "========== debug ==========";

}

# crc_check ( $crcold, \@data )
# data is an array of bytes as numbers
sub crc_check {
   my $crc = shift @_;
   $ary = shift @_;
   foreach my $x ( @$ary ) {
           my $oldcrc = $crc;
           $crc = ($crc + $x ) % 0x100 ;
	   # printf  ( " %02x - %02x -> %02x \n", $oldcrc,  $x ,  $crc   );
    }
    #  die "========== debug ==========";
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
  # don't try useless work 
  my $parlen = $#_ +1 ;
  return undef unless $parlen  == 10 ;
  
  # the cumbersome part - see def of log stream
  $EOC_volt = little_endian( splice (@_, 0,2)) / 1000;
  $mode = shift @_;
  $current = little_endian( splice (@_, 0,2)) / 10; 
  $t1 = little_endian( splice (@_, 0,2))  / 10;
  $t2 = little_endian( splice (@_, 0,2))  / 10;
  $SOC= shift @_;

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

  # remove the last 12 bytes for fixed vars, leaving the rest for per cell voltages
  @tail12 = splice (@_, -12) ;

  $Wh_maybe = big_endian( splice (@tail12 , 0 , 4 ) ) / 1000 ;
  $Ah_maybe = big_endian( splice (@tail12 , 0 , 4 ) ) / 1000 ;
  $dontknow_maybe = big_endian( splice (@tail12 , 0 , 4 ) ) / 1000 ;
 
  # the rest are per cell voltage readings
  my @cell_volts = () ;
  # while ($#_) {
  # for ( my @cell_volts = () , my $cv = little_endian( splice (@_, 0,2)) / 1000, $#_ ) {
	  # my $cv = little_endian( splice (@_, 0,2)) / 1000;  
	  # for (my $cnt = $#_ ; $cnt -= 2; $cnt <=0 ) {
    
	  #push ( @cell_volts, $cv   );
	  # push ( @cell_volts , little_endian( splice (@_, 0,2))  / 1000 );  
	  # }


	  # while ( 0 ) {
	  # print Dumper (\@_); 
  #foreach $i (1 .. ($#_ / 2) ) {  
  while (scalar @_ >0 ) {
    # $p1 = shift @_;
    # $p2 = shift @_;
    #    $p3 = shift @_;
    # $p4 = shift @_;

    # $cv = ( little_endian($p1, $p2) / 1000 );
    # push ( @cell_volts, $cv   );
    push ( @cell_volts , little_endian( splice (@_, 0,2))  / 1000 );
  }	  

  # print Dumper (\@_, \@cell_volts);
  

  # collect the findings
  my %res ;
  $res{'num_param'} = $parlen ;
  $res{'Wh?'} = $Wh_maybe ;
  $res{'Ah?'} = $Ah_maybe ;
  $res{'gww???'} = $dontknow_maybe ; 
  # $res{'} =
  # $res{'} =
  # $res{'} =
  $res{'cell_volts'} = \@cell_volts ; 
  $res{'num_param'} = $parlen;

  $res{'rest'} = \@_;
  $res{'tail'} = \@tail12 ;

  return \%res ;

}
  

# do_58 (@data) - crc already stripped
sub do_58 {
  return undef
}
