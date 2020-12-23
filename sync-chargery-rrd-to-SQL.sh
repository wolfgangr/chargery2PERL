#!/bin/bash

# may put this into cronfile
#  so better to be sure to feel at home...

SCRIPTDIR=`dirname "$0"`
cd $SCRIPTDIR

# and be known there...
. secret.pwd

for TAG in cells pack56 pack57 
  do
	TABLENAME=rrd_upload_${TAG}
	TEMPFILE=${TMPDIR}/${TABLENAME}.csv
	RRDFILE=${TAG}.rrd
	# ./rrd2csv.pl pack56.rrd AVERAGE -r 300 -x\; -M -t -f maria1-csv

	echo $RRDFILE ' -> ' $TEMPFILE
	# echo $TEMPFILE
	# echo ${TABLENAME}
	# exit

	./rrd2csv.pl $RRDFILE AVERAGE -r 300 -x\; -M -t -f $TEMPFILE

	# mysqlimport -h homeserver -u solarlog-writer -pfoo --local --force  
	#	--ignore-lines=1   --fields-terminated-by=';'   -d   chargery 'maria1.csv'

  	mysqlimport -h $HOST -u $USER -p$PASSWD  --local \
		--ignore --force \
		--ignore-lines=1 --fields-terminated-by=';' \
		chargery $TEMPFILE
  done

