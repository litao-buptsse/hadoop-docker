#!/bin/bash

if [ $# -ne 1 ]; then
  echo "usage: $0 <pidfile>"
  exit 1
fi

pidfile=$1
pid=`cat $pidfile`

while true; do
  kill -0 $pid
  ext=$?
  if [ $ext -ne 0 ]; then
    exit $ext
  fi
  sleep 5
done
