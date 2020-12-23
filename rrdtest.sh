#!/bin/bash
# 
RRD=$1
rrdtool last $RRD | date -d @`cat -`   

