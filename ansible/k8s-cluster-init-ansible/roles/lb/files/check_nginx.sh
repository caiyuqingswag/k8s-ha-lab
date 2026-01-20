#!/bin/bash
counter=$(ps -ef |grep nginx | grep sbin | egrep -cv "grep|$$")
if [ $counter -eq 0 ]; then
    systemctl start nginx
    sleep 2
    counter=$(ps -ef |grep nginx | grep sbin | egrep -cv "grep|$$")
    if [ $counter -eq 0 ]; then
        systemctl stop keepalived
    fi
fi
