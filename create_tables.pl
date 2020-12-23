#!/usr/bin/perl
# crude hack to create tables
our $num_cells = 22;

our %table_defs;

use Data::Dumper;

print Dumper( \%table_defs ) ;


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

