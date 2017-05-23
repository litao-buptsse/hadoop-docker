#!/bin/bash

dir=`pwd`
dataDir=$dir/data
logDir=$dir/logs

host=`hostname`
nodeType=`grep =$host conf/cluster_topology.txt | grep ^master |  awk -F"=" '{print $1}'`
if [ X$nodeType == X ]; then
  nodeType=`grep =$host conf/cluster_topology.txt | grep ^slave |  awk -F"=" '{print $1}'`
  if [ X$nodeType == X ]; then
    echo "no such host in cluster_topology.txt"
    exit 1  
  fi
fi

if [ $# -lt 1 ]; then
  echo "$0 <module>"
  exit 1
fi

dir=`pwd`
module=$1; shift
version=2.6.0-cdh5.10.0

if [ -f conf/VERSION ]; then
 version=`cat conf/VERSION`
fi

startCommand=""
pidfile=""
case $module in
  shell)
    startCommand="/bin/bash"
    ;;
  hadoop)
    startCommand="bin/hadoop $@"
    ;;
  hdfs)
    startCommand="bin/hdfs $@"
    ;;
  example)
    startCommand="bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-${version}.jar pi 3 4"
    ;;
  formatNamenode)
    startCommand="bin/hdfs namenode -format -clusterId CID-f5586ada-3a6e-4dce-a189-ac77374c1b48"
    ;;
  bootstrapStandby)
    startCommand="bin/hdfs namenode -bootstrapStandby"
    ;;
  formatZkfc)
    startCommand="bin/hdfs zkfc -formatZK"
    ;;
  namenode)
    startCommand="sbin/hadoop-daemon.sh --config etc/hadoop --script hdfs start namenode $@"
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
  resourcemanager)
    startCommand="sbin/yarn-daemon.sh --config etc/hadoop start resourcemanager"
    pidfile="/tmp/yarn--resourcemanager.pid"
    ;;
  nodemanager)
    startCommand="sbin/yarn-daemon.sh --config etc/hadoop start nodemanager"
    pidfile="/tmp/yarn--nodemanager.pid"
    ;;
  timelineserver)
    exist=`./run.sh hadoop fs -ls hdfs://ns1/ | grep "/app-logs" | wc -l`
    if [ $exist -eq 0 ]; then
      ./run.sh hadoop fs -mkdir -p hdfs://ns1/app-logs
      ./run.sh hadoop fs -chmod -R 777 hdfs://ns1/app-logs
    fi
    startCommand="sbin/yarn-daemon.sh --config etc/hadoop start timelineserver"
    pidfile="/tmp/yarn--timelineserver.pid"
    ;;
  historyserver)
    startCommand="sbin/mr-jobhistory-daemon.sh --config etc/hadoop start historyserver"
    pidfile="/tmp/mapred--historyserver.pid"
    ;;
  zookeeper)
    mkdir -p $dataDir/zookeeper
    if [ ! -f $dataDir/zookeeper/myid ]; then
      myid=`echo $nodeType | awk -F"master" '{print $2}'`
      if [ X$myid != X ]; then
        echo $myid > $dataDir/zookeeper/myid
      fi
    fi
    startCommand="cd /search/zookeeper; bin/zkServer.sh start"
    pidfile="/search/data/zookeeper/zookeeper_server.pid"
    ;;
  *)
    echo "no such module $module"
    exit 1
    ;;
esac

# pull latest image
docker pull docker.registry.clouddev.sogou:5000/hadoop/minicluster:$version

# kill running container
docker ps --filter "name=$module" --format "{{.ID}}"  | xargs -r docker kill

# init config file
./init.sh

mkdir -p $dataDir $logDir


if [ X$pidfile != X ]; then
  startCommand="$startCommand && /search/hadoop/wait.sh $pidfile"
  docker run -d \
    --name=$module --net=host --rm \
    -v $dir/conf/$nodeType/hadoop_conf:/search/hadoop/etc/hadoop \
    -v $dir/conf/$nodeType/zookeeper_conf:/search/zookeeper/conf \
    -v $logDir:/search/hadoop/logs \
    -v $dataDir:/search/data \
    docker.registry.clouddev.sogou:5000/hadoop/minicluster:$version sh -c "$startCommand"
else
  docker run -it \
    --name=$module --net=host --rm \
    -v $dir/conf/$nodeType/hadoop_conf:/search/hadoop/etc/hadoop \
    -v $dir/conf/$nodeType/zookeeper_conf:/search/zookeeper/conf \
    -v $logDir:/search/hadoop/logs \
    -v $dataDir:/search/data \
    docker.registry.clouddev.sogou:5000/hadoop/minicluster:$version $startCommand
fi
