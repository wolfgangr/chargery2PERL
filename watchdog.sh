#!/bin/bash

cd ~wrosner/chargery/rrd
PROCESS='update.pl'
CALLER='/usr/bin/perl'
LOGFILE='/var/log/wrosner/watchdog_rrd.log'
UPDLOG='/var/log/wrosner/chargery_update.log'

# exit - nothing to do if rrdtest reports success
./rrdtest.pl *.rrd 2>> $LOGFILE 1> /dev/null 
if [ $? ] ; then 
	exit
fi

echo -n "chargery rrd watchdog triggered at " >> $LOGFILE
date >> $LOGFILE

ps ax | grep './update.pl' | grep '/usr/bin/perl' >> $LOGFILE

killall update.pl >>  $LOGFILE
sleep 3
killall -9 update.pl >> >> $LOGFILE
sleep 3

setstty-RS485.sh 2>&1 >> $LOGFILE
update.pl & 2>&1 >> $UPDLOG


