#!/usr/bin/perl
#
# extract data from rrd and write csv data
# usage plan: rrd2csv.pl db CF from to header sep delim
#
# idie @ARGV
#


# we need at least a rrd file name and a CF
die "usage $0 db.rrd CF [-s start] [-e end] [-h] [-x sep] [-d delim] " unless $#ARGV >= 1;

