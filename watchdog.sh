#!/bin/bash

cd ~wrosner/chargery/rrd
PROCESS='update.pl'
CALLER='/usr/bin/perl'
LOGFILE='/var/log/wrosner/watchdog_rrd.log'
UPDLOG='/var/log/wrosner/chargery_update.log'

# uncomment this 2 line for debug
echo -n "chargery rrd watchdog entered " >> $LOGFILE
date >> $LOGFILE


# exit - nothing to do if rrdtest reports success
./rrdtest.pl *.rrd   2>> $LOGFILE | tail -n1 >> $LOGFILE 
STATUS=${PIPESTATUS[0]}
if [ $STATUS -eq 0 ] ; then
	exit
fi



echo -n "chargery rrd watchdog triggered at " >> $LOGFILE
date >> $LOGFILE

ps ax | grep './update.pl' | grep '/usr/bin/perl' >> $LOGFILE

killall update.pl  >>  $LOGFILE 2>&1
sleep 1 
killall -9 update.pl  >> $LOGFILE 2>&1
sleep 1

./setstty-RS485.sh  >> $LOGFILE 2>&1
./update.pl &  >> $UPDLOG 2>&1


