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

while ($nbytes = read DATAIN, $data, 1) {

  # do stuff
  print ".";
  $byte = ord ($data);
  $hex = sprintf ("%02x", $byte);
  $ihex = sprintf ("%02x", $byte ^ hex('ff'));
  print "\n" if ( $ihex eq '24');
  printf ("%d:%s-%s|", $nbytes, $hex, $ihex );


}


close DATAIN or die "Eror closing $filename $!\n";

print "\n\n    ==================== regular END ===============\n\n";
