#!/bin/bash
while [ "$1" != "" ]
do
        echo "/D`echo $1|awk -F '.' '{print $2}'`/R`echo $1|awk -F '.' '{print $3}'`";
shift 1
done
