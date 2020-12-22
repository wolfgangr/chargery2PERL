#!/usr/bin/perl
# use String::Dump "dump_hex";

my $device ="../dev_chargery";

# $SIG{INT}  = \&sig_term_handler;

system("setstty-RS485.sh");

# my $inpipe = "cat $device | expect_unbuffer -p | ";

# my $inpipe = "cat $device | ";

$inpipe = $device;

open (DATAIN, $inpipe) || die (sprintf "cannot open >%s< \n", $inpipe) ;

my $data;
my $nbytes;
$terminate=false;

while (true) {
  $nbytes = read DATAIN, $data, 15;
  
  my @datarray= map (ord, split (undef, $data)); 
  hexdump ( @datarray );
  print "\n";
}

close DATAIN;

exit;

#------------------------------------

sub sig_term_handler {
  debug_print (1, "caught TERM signal - $! \n");
  $terminate = true;
}

sub hexdump {
    # $level = shift @_;
    # return unless ( $level <= $debug) ;
    # $ary = shift @_;
    # print Dumper ( @$ary ) ;

    foreach my $x ( @_ ) {
      printf   ( " %02x", $x );
    }
    # print "--\n";
    # die "========== debug ==========";

}
