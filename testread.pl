#!/usr/bin/perl
#
# https://blog-en.openalfa.com/how-to-work-with-binary-data-in-a-perl-script


my $filename = "test.raw" ;

$debug = 5;


open DATAIN, $filename
	or die "Error opening binary input file $filename: !$\n";

# set stream to binary mode
binmode DATAIN;

my $data;
my $nbytes;

my $status =0;

while ($nbytes = read DATAIN, $data, 1) {

  # do stuff
  # print ".";
  $byte = ord ($data);
  $hex = sprintf ("%02x", $byte);
  # $ihex = sprintf ("%02x", $byte ^ hex('ff'));
  # print "\n" if ( $hex eq '24');
  # printf (" %s", $hex );

  # do the state machine
  if ( $hex eq '24') {
    $status++;
    debug_print (5, "\n*- " ) if ($status == 1) ;
    if ($status > 2) {
	debug_print (5, "\t.oopsie - too many 24'rs \n" );
	$status = 0;
    }
    # } else {
	  # $status = 0;
  } 
  debug_print (5,  sprintf(" %s", $hex ));

  if ($status >= 2 ) {
    if (($hex eq '57') || ($hex eq '58')) {
      $status = $byte;
      }
    } elsif ($status = 2 ) {
      debug_print (5, "\t-# oopsie - unrecognized data set \n");
      # $status = 0;

    } else {
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
