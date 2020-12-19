#!/usr/bin/perl
#
# https://blog-en.openalfa.com/how-to-work-with-binary-data-in-a-perl-script


my $filename = "test.raw" ;

$debug = 6;


open DATAIN, $filename
	or die "Error opening binary input file $filename: !$\n";

# set stream to binary mode
binmode DATAIN;

my $data;
my $nbytes;

my $status =0;
my $fieldpos =0;

while ($nbytes = read DATAIN, $data, 1) {

  $byte = ord ($data);
  $hex = sprintf ("%02x", $byte);
  # debug_print (6,  sprintf(" >%s", $hex ));

  $fieldpos++;

  # check syntax cascade
  if ( ($byte == 24) 
    if ($fieldpos ==1) or ($fieldpos ==2 ) {
      debug_print (5, "'"); 
    } else {
      debug_print (5, "x24-garbage %s at pos %d\n", $hex, $fieldpos)
      $fieldpos = 0;
    }
  } elsif {( $byte == 57 ) or (&byte == 58) ) {
    if  ($fieldpos ==3 ) {
      debug_print (5, "'");
    } else {
      debug_print (5, "x5X-garbage %s at pos %d\n", $hex, $fieldpos)
      $fieldpos = 0;
    }

  } elsif ($fieldpos >=1) {
    debug_print (5, "xXX-garbage %s at pos %d\n", $hex, $fieldpos)
    $fieldpos = 0;

  } else {
    # data field still to recognize
    # debug_print (5, " %s", $hex);
    debug_print (5, " ?");
  }
  debug_print (5, "%s", $hex);

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # do the state machine
  if ( $hex eq '24') {
	  # $status++;
    debug_print (5, "\n*- " ) if ($status == 1) ;
    if ($status > 2) {
	debug_print (5, sprintf ("\t.oopsie - too many 24'rs - status %d \n", $status) );
	$status = 0;
    } elsif ($status == 1) {
       debug_print (5, "\n-*- ");
    }

    # } else {
	  # $status = 0;
  } 
  debug_print (5,  sprintf(" %s", $hex ));

  if ($status >= 2 ) {
    if (($hex eq '57') || ($hex eq '58')) {
      $status = $byte;
      }
    } elsif ($status > 2 ) {
      debug_print (5, "\t-# oopsie - unrecognized data set \n");
      # $status = 0;

    } else {
	    # garbage    
      debug_print (5, ".");
  }


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
