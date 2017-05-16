#!/bin/bash

dataDir=/tmp/minicluster/data
logDir=/tmp/minicluster/logs

host=`hostname`
nodeType=`grep =$host cluster_topology.txt | grep ^master |  awk -F"=" '{print $1}'`
if [ X$nodeType == X ]; then
  nodeType=`grep =$host cluster_topology.txt | grep ^slave |  awk -F"=" '{print $1}'`
  if [ X$nodeType == X ]; then
    echo "no such host in cluster_topology.txt"
    exit 1  
  fi
fi

if [ $# -lt 1 ]; then
  echo "$0 <module> [version]"
  exit 1
fi

dir=`pwd`
module=$1
version=2.6.0-cdh5.10.0
if [ $# -ge 2 ]; then
  version=$2
fi

startCommand=""
case $module in
  namenode)
    startCommand="sbin/hadoop-daemon.sh --config etc/hadoop --script hdfs start namenode"
    ;;
  journalnode)
    startCommand="sbin/hadoop-daemon.sh --config etc/hadoop start journalnode"
    ;;
  zkfc)
    startCommand="sbin/hadoop-daemon.sh --config etc/hadoop --script hdfs start zkfc"
    ;;
  datanode)
    startCommand="sbin/hadoop-daemon.sh --config etc/hadoop --script hdfs start datanode"
    ;;
  *)
    echo "no such module $module"
    exit 1
    ;;
esac

docker run -it \
  --net=host --rm \
  -v $dir/conf/$nodeType/hadoop_conf:/search/hadoop/etc/hadoop \
  -v $dir/conf/$nodeType/zookeeper_conf:/search/zookeeper/conf \
  -v $logDir:/search/hadoop/logs \
  -v $dataDir:/search/data \
  docker.registry.clouddev.sogou:5000/hadoop/minicluster:$version $startCommand
