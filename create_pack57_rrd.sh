#!/bin/bash
# skript to generate rrd files
# generated by 
# ./metacreate_pack57_rrd.pl  \
/usr/bin/rrdtool create pack57.rrd --start NOW --step 5  \
DS:curr:GAUGE:10:-500:500  \
DS:mode:GAUGE:10:0:2  \
DS:Vend_c:GAUGE:10:0:4  \
DS:SOC:GAUGE:10:0:100  \
DS:temp1:GAUGE:60:-30:100  \
DS:temp2:GAUGE:60:-30:100  \
RRA:AVERAGE:0.5:2:86400  \
RRA:MIN:0.5:60:26000  \
RRA:MAX:0.5:60:26000  \
RRA:AVERAGE:0.5:60:26000  \
RRA:MIN:0.5:720:10000  \
RRA:MAX:0.5:720:10000  \
RRA:AVERAGE:0.5:720:10000  \
RRA:MIN:0.5:17280:22000  \
RRA:MAX:0.5:17280:22000  \
RRA:AVERAGE:0.5:17280:22000  \
