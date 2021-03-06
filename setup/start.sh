#!/bin/bash

# systemd starter script

UPDLOG='/var/log/wrosner/chargery_update.log'
DEVICE='../../dev_chargery'

SCRIPTDIR=`dirname "$0"`
# echo $SCRIPTDIR
cd $SCRIPTDIR

# spawn our associated babysitter
./watchdog_chargery.pl &

# like unplugging / replugging
./reset_ttyUSB.pl $DEVICE
sleep 2

cd ..

./setstty-RS485.sh  >> $UPDLOG  


./update.pl    >> $UPDLOG  


# report success to sysstemd just in case it's configured to ask for
# exit 0
