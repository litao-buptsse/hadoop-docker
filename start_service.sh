#!/bin/bash

dataDir=/search/ted/minicluster/data
logDir=/search/ted/minicluster/logs

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
pidfile=""
case $module in
  shell)
    startCommand="/bin/bash"
    ;;
  format)
    startCommand="bin/hdfs namenode -format minicluster"
    ;;
  bootstrapStandby)
    startCommand="bin/hdfs namenode -bootstrapStandby"
    ;;
  namenode)
    startCommand="sbin/hadoop-daemon.sh --config etc/hadoop --script hdfs start namenode"
    pidfile="/tmp/hadoop--namenode.pid"
    ;;
  journalnode)
    startCommand="sbin/hadoop-daemon.sh --config etc/hadoop start journalnode"
    pidfile="/tmp/hadoop--journalnode.pid"
    ;;
  zkfc)
    startCommand="sbin/hadoop-daemon.sh --config etc/hadoop --script hdfs start zkfc"
    pidfile="/tmp/hadoop--zkfc.pid"
    ;;
  datanode)
    startCommand="sbin/hadoop-daemon.sh --config etc/hadoop --script hdfs start datanode"
    pidfile="/tmp/hadoop--datanode.pid"
    ;;
  *)
    echo "no such module $module"
    exit 1
    ;;
esac

mkdir -p $dataDir $logDir
echo $startCommand

docker pull docker.registry.clouddev.sogou:5000/hadoop/minicluster:$version

if [ $module == "shell" ] || [ $module == "format" ] || [ $module == "bootstrapStandby" ]; then
  docker run -it \
    --net=host --rm \
    -v $dir/conf/$nodeType/hadoop_conf:/search/hadoop/etc/hadoop \
    -v $dir/conf/$nodeType/zookeeper_conf:/search/zookeeper/conf \
    -v $logDir:/search/hadoop/logs \
    -v $dataDir:/search/data \
    docker.registry.clouddev.sogou:5000/hadoop/minicluster:$version $startCommand
else
  startCommand="$startCommand && ./wait.sh $pidfile"
  docker run -d \
    --net=host --rm \
    -v $dir/conf/$nodeType/hadoop_conf:/search/hadoop/etc/hadoop \
    -v $dir/conf/$nodeType/zookeeper_conf:/search/zookeeper/conf \
    -v $logDir:/search/hadoop/logs \
    -v $dataDir:/search/data \
    docker.registry.clouddev.sogou:5000/hadoop/minicluster:$version sh -c "$startCommand"
fi
