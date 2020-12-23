#!/usr/bin/perl
# crude hack to create tables
# print debug to SDTERR
# working output to file

our $num_cells = 22;

# we only have decimal numeric fields
# hash of tables => hash of rows => array [ width , decimals ]
our %table_defs = ( 

  cells => {
	# U01 U02 ...  U22
  } ,
  pack56 => {
	Vtot	=> [ 6,4 ] , 
	Ah	=> [ 6,2 ] ,
	Wh	=> [ 8,3 ] ,
  } ,
  pack57 => {
	curr	=> [ 6,4 ] ,
	mode	=> [ 6,4 ] ,
	Vend_c	=> [ 6,4 ] ,
	SOC	=> [ 6,4 ] ,
	temp1	=> [ 6,4 ] ,
	temp2	=> [ 6,4 ] ,
  } ,
);

# ==== automagic config of table cols per cell

my %def_cells;
for $cell (1 .. $num_cells) {
   $def_cells{ sprintf "U%02d", $cell } = [ 6,4 ] ;
}

$table_defs{'cells'} = \%def_cells;

# ===== end of config

use Data::Dumper;

print STDERR Dumper( \%table_defs ) ;


my $tabdef_head = <<"EOF_TDHEAD";
/*!40101 SET \@saved_cs_client     = \@@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
/*!40101 SET character_set_client = \@saved_cs_client */;
EOF_TDTAIL

#========== assemble defs ==================

# loop over tables


# loop over fields

# add field definition


