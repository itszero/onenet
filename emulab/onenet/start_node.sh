#!/bin/sh
PNO=$1

sudo mn -c
ps ax | grep python | awk '{print $1}' | xargs sudo kill
python -u log_wrapper.py net-$PNO sudo python -u net.py $PNO topo.js
