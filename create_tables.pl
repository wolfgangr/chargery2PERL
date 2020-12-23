#!/usr/bin/perl
# crude hack to create tables
# print debug to SDTERR
# working output to file
#
# https://perldoc.perl.org/perldsc#Declaration-of-a-HASH-OF-ARRAYS

our $num_cells = 22;
our $tablename_prefix ="rrd_upload_" ;

# we only have decimal numeric fields
# hash of tables => hash of rows => array [ width , decimals ]
our %table_defs = ( 

  cells => {
	# U01 U02 ...  U22
  } ,
  pack56 => {
	seq => 2,
        #	[ seq, digits, decimals ]	
	Vtot	=> [ 1, 6,4 ] , 
	Ah	=> [ 2, 6,2 ] ,
	Wh	=> [ 3, 8,3 ] ,
  } ,
  pack57 => {
	seq => 3, 
	curr	=> [ 1, 6,3 ] ,
	mode	=> [ 2, 1,0 ] ,
	Vend_c	=> [ 3, 4,3 ] ,
	SOC	=> [ 4, 3,0 ] ,
	temp1	=> [ 5, 4,2 ] ,
	temp2	=> [ 6, 4,2 ] ,
  } ,
);

# ==== automagic config of table cols per cell

my %def_cells;
for $cell (1 .. $num_cells) {
   $def_cells{ sprintf "U%02d", $cell } = [ $cell  ,  4,3 ] ;
}
$def_cells{ 'seq' } = 1;
$table_defs{'cells'} = \%def_cells;

# ===== end of config

use Data::Dumper;

print STDERR Dumper( \%table_defs ) ;

my $outer_head = <<"EOF_OHEAD";
/*!40101 SET character_set_client = utf8 */;

EOF_OHEAD

my $tabdef_head = <<"EOF_TDHEAD";
DROP TABLE IF EXISTS `%s`;
CREATE TABLE `%s` (
  `time` datetime NOT NULL,
EOF_TDHEAD

my $tabdef_row = <<"EOF_TDROW" ;
  `%s` decimal(%d,%d) DEFAULT NULL,
EOF_TDROW
  
my $tabdef_tail = <<"EOF_TDTAIL";
  `update_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  PRIMARY KEY (`time`)
) ENGINE=MyISAM DEFAULT CHARSET=ascii ;

EOF_TDTAIL

#=============== pull the stuff apart

print STDERR "========== start parsing data tree \n ==========";

# prelude
print $outer_head;

# cycle over tables
foreach my $table ( 
	sort { $table_defs{ $a }->{'seq' }<=> $table_defs{ $b }->{'seq' } }  
	keys %table_defs ) {

  # print STDERR "building  table  $table \n"; 
  my $tbd = $table_defs{$table};
  my $tablename = $tablename_prefix . $table ;
  print STDERR " building  table  $tablename ,  sequence = $tbd->{'seq' }   \n";
  # print STDERR Dumper $tbd ;

  # do the real thing - fill with table name
  printf $tabdef_head, $tablename, $tablename ;

  # cycle over rows
  foreach my $trow ( 
	  sort {    $$tbd{ $a }[0]  <=>  $$tbd{ $b }[0]    }
	  keys %$tbd ) {
    next if $trow eq 'seq' ;
    my $trd = %$tbd{$trow} ;
    # print STDERR Dumper $trd ;
    print STDERR " +----  building  row  $trow,  sequence = $$trd[0] param: $$trd[1] , $$trd[2]   \n";


    # do the real thing
    printf $tabdef_row,  $trow, $$trd[1] , $$trd[2]   ;
  }

  # finish the real thing
  print $tabdef_tail;

}
