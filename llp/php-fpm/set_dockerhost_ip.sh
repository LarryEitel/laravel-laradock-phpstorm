#!/bin/bash

if [[ -z $(grep dockerhost /etc/hosts) ]]
then
    echo `/sbin/ip route|awk '/default/ { print $3 }'` dockerhost >> /etc/hosts
fi
