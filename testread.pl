#!/usr/bin/perl
#
# https://blog-en.openalfa.com/how-to-work-with-binary-data-in-a-perl-script


my $filename = "test.raw" ;

# $debug = 6;


open DATAIN, $filename
	or die "Error opening binary input file $filename: !$\n";

# set stream to binary mode
binmode DATAIN;

my $data;
my $nbytes;

my $status =0;
my $fieldpos =0;

$debug = 5;
while ($nbytes = read DATAIN, $data, 1) {

  $byte = ord ($data);
  $hex = sprintf ("%02x", $byte);
  debug_printf (6, " (%s <- %d) ", $hex  , $byte );

  $fieldpos++;

  # check syntax cascade
  if  ($byte == 0x24) { 
    if ( ($fieldpos ==1) or ($fieldpos ==2 ) ) {
      debug_print (5, "'"); 
    } else {
      debug_print (5, "x24-garbage %s at pos %d\n", $hex, $fieldpos) ;
      $fieldpos = 0;
    }
  } elsif ( ( $byte == 0x56 ) or  ( $byte == 0x57 ) or ( $byte == 0x58) ) {
    if  ($fieldpos ==3 ) {
      debug_print (5, "'");
    } else {
      debug_print (5, "x5X-garbage %s at pos %d\n", $hex, $fieldpos) ;
      $fieldpos = 0;
    }

  } elsif ($fieldpos <= 3) {
    debug_printf (5, "xXX-garbage %s at pos %d\n", $hex, $fieldpos) ;
    $fieldpos = 0;

  } else {
    # data field still to recognize
    # debug_print (5, " %s", $hex);
    debug_print (5, " ?");
  }
  debug_printf (5, " >%s< ", $hex);

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

