#!/usr/bin/env bash

sudo mn -c
ps ax | grep python | awk '{print $1}' | xargs sudo kill
PYRO_SERIALIZERS_ACCEPTED='pickle' PYRO_SERIALIZER='pickle' PYRO_SOCK_REUSE="true" python -m Pyro4.naming -n 10.0.50.50 &
(cd pox; python ~/onenet/log_wrapper.py pox ./pox.py controller) &
cd ~/onenet
python -u main.py topo.js
ps ax | grep python | awk '{print $1}' | xargs sudo kill
