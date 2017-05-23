#!/bin/bash
set -o pipefail

dirPath=/var/log/hadoop-yarn

mail_cmd=$dirPath/send_alert.php
mail_list=shenxianqiang@sogou-inc.com
host_name=`hostname`

cpuCore=$(cat /proc/cpuinfo  | grep -w "^processor" -c)
if [ -z "$cpuCore" ];then
  cpuCore=32
fi

maxLoad=$(echo "$cpuCore*2.0" | bc)
maxTime=3600

(
  exec 200>$dirPath/healthcheck.lock
  if flock -n -x 200;then
    timestamp=`date +%s`
    currentLoad=$(w | head -1 | awk 'BEGIN{FS=":"}{print $NF}' | awk 'BEGIN{FS=","}{print $2}' | awk '{print $NF}')
    var=$(awk -v a=$currentLoad -v b=$maxLoad 'BEGIN { print (a >= b) ? "YES" : "NO" }')
    if [ $var == "YES" ];then
      if [ ! -e "$dirPath/currentLoad" ];then
        echo "$timestamp 0 $currentLoad" > $dirPath/currentLoad
        exit 0
      fi
      cur=$(cat $dirPath/currentLoad)
      last_stamps=$(echo $cur | awk '{print $1}')
      last_duration=$(echo $cur | awk '{print $2}')
      duration=$(($timestamp - $last_stamps))
      highLoadDuration=$(($duration + $last_duration))
      if [ $highLoadDuration -ge $maxTime ];then
         echo "$timestamp 0 $currentLoad" > $dirPath/currentLoad
         php $mail_cmd $mail_list shenxianqiang@sogou-inc.com "$host_name load is too high" "Warning : host:$host_name,current load : $currentLoad,duration : $highLoadDuration,Please Check" now 1
         exit 0
      fi
      echo "$timestamp $highLoadDuration $currentLoad" > $dirPath/currentLoad
      exit 0
    fi
    echo "$timestamp 0 $currentLoad" > $dirPath/currentLoad
    exit 0
  fi
)
