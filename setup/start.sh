#!/bin/bash

# systemd starter script

UPDLOG='/var/log/wrosner/chargery_update.log'

SCRIPTDIR=`dirname "$0"`
# echo $SCRIPTDIR
cd $SCRIPTDIR

# spawn our associated babysitter
./watchdog.pl &

# not sure what environment we get from systemd
# echo $PATH
# pwd
cd ..
# source /etc/profile
# source ~/.profile
# echo $PATH
# pwd
# launch the real thing
# SCRIPTDIR/../log2rrd.pl &
# ./log2rrd.pl > /dev/null 

./setstty-RS485.sh  #   >> $LOGFILE 2>&1


./update  >> $UPDLOG 2>&1


# report success to sysstemd just in case it's configured to ask for
# exit 0