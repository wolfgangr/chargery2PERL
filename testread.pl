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
$debug = 5;

while ($nbytes = read DATAIN, $data, 1) {

  $byte = ord ($data);
  $hex = sprintf ("%02x", $byte);
  debug_printf (6, " (%s <- %d) ", $hex  , $byte );

  # update field counter and crd
  unless ( $fieldpos )  { $crc = 0; }
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
      debug_print (5, "'");
    } else {
      debug_printf (5, "x5X-garbage %s at pos %d\n", $hex, $fieldpos) ;
      $fieldpos = 0;
    }

  } elsif (($fieldpos == 1) and ( $byte == 0x68 ) ) {
    # separator 68 3a 3a 33 0d 0a  aka "h::3\cr\lf"
    $nbytes = read DATAIN, $data, 5;
    if ($debug >= 2) {
      if ($data =~ m/(::3)$/) {
	 debug_printf (3, "spacer %c%s skipped\n", $byte, $1) ;
      } else {
        debug_printf (2, "unknown spacer %c.%x\n", $byte, $data)  ;	
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
