#!/usr/bin/perl
#
# https://blog-en.openalfa.com/how-to-work-with-binary-data-in-a-perl-script


my $filename = "test.raw" ;
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
    print "\n" if ($status == 1) ;
    if ($status > 2) {
	print "\t.oopsie - too many 24'rs \n";
	$status = 0;
    }
  } else {
    $status = 0;
  } 
  printf (" %s", $hex );


}


close DATAIN or die "Eror closing $filename $!\n";

print "\n\n    ==================== regular END ===============\n\n";
