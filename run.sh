#!/bin/bash

dir=`pwd`
dataDir=$dir/data
logDir=$dir/logs
mntDir=$dir/mnt

host=`hostname`
nodeType=`grep =$host conf/cluster_topology.txt | grep ^master |  awk -F"=" '{print $1}'`
if [ X$nodeType == X ]; then
  nodeType=`grep =$host conf/cluster_topology.txt | grep ^slave |  awk -F"=" '{print $1}'`
  if [ X$nodeType == X ]; then
    echo "no such host in cluster_topology.txt"
    exit 1  
  fi
fi

if [ $# -lt 2 ]; then
  echo "$0 <version> <module>"
  exit 1
fi

dir=`pwd`
version=$1; shift
module=$1; shift

startCommand=""
pidfile=""
ugiConfig=""
case $module in
  shell)
    startCommand="/bin/bash"
    nodeType="client"
    ugiConfig="slave"
    ;;
  adminShell)
    startCommand="/bin/bash"
    nodeType="client"
    ugiConfig="mapred"
    ;;
  hadoop)
    startCommand="bin/hadoop $@"
    nodeType="client"
    ugiConfig="slave"
    ;;
  adminHadoop)
    startCommand="bin/hadoop $@"
    nodeType="client"
    ugiConfig="mapred"
    ;;
  hdfs)
    startCommand="bin/hdfs $@"
    ;;
  pi)
    startCommand="bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-${version}.jar pi 3 4"
    nodeType="client"
    ugiConfig="slave"
    ;;
  wordcount)
    nodeType="client"
    ugiConfig="slave"
    cp $dir/README.md $mntDir
    ./run.sh 2.5.0-cdh5.3.2 hadoop fs -mkdir -p hdfs://ns1/logdata
    ./run.sh 2.5.0-cdh5.3.2 hadoop fs -put -f /search/mnt/README.md /logdata
    ./run.sh 2.5.0-cdh5.3.2 hadoop fs -mkdir -p hdfs://ns2/user/$ugiConfig
    ./run.sh 2.5.0-cdh5.3.2 hadoop fs -rm -r /user/$ugiConfig/wordcount_output
    startCommand="bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-${version}.jar wordcount /logdata/README.md /user/$ugiConfig/wordcount_output"
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
      ./run.sh hadoop 2.5.0-cdh5.3.2 fs -mkdir -p hdfs://ns1/app-logs
      ./run.sh hadoop 2.5.0-cdh5.3.2 fs -chmod -R 777 hdfs://ns1/app-logs
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
  shutdownAll)
    service docker restart
    exit
    ;;
  cleanAll)
    service docker restart
    rm -fr data logs
    exit
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

mkdir -p $dataDir $logDir $mntDir

if [ X$pidfile != X ]; then
  # type 1: deamon
  startCommand="$startCommand && /search/hadoop/wait.sh $pidfile"
  docker run -d \
    --name=$module --net=host --rm \
    -v $dir/conf/$nodeType/hadoop_conf:/search/hadoop/etc/hadoop \
    -v $dir/conf/$nodeType/zookeeper_conf:/search/zookeeper/conf \
    -v $logDir:/search/hadoop/logs \
    -v $dataDir:/search/data \
    -v $mntDir:/search/mnt \
    docker.registry.clouddev.sogou:5000/hadoop/minicluster:$version sh -c "$startCommand"
elif [ $nodeType != client ]; then
  # type 2: command exec on server (no ugi_config file)
  docker run -it \
    --name=$module --net=host --rm \
    -v $dir/conf/$nodeType/hadoop_conf:/search/hadoop/etc/hadoop \
    -v $dir/conf/$nodeType/zookeeper_conf:/search/zookeeper/conf \
    -v $logDir:/search/hadoop/logs \
    -v $dataDir:/search/data \
    -v $mntDir:/search/mnt \
    docker.registry.clouddev.sogou:5000/hadoop/minicluster:$version $startCommand
else
  # type 3: command exec on client (with ugi_config file)
  docker run -it \
    --name=$module --net=host --rm \
    -v $dir/conf/$nodeType/hadoop_conf:/search/hadoop/etc/hadoop \
    -v $dir/conf/$nodeType/zookeeper_conf:/search/zookeeper/conf \
    -v $logDir:/search/hadoop/logs \
    -v $dataDir:/search/data \
    -v $mntDir:/search/mnt \
    -v $dir/conf/ugi_config/$ugiConfig:/root/ugi_config \
    docker.registry.clouddev.sogou:5000/hadoop/minicluster:$version $startCommand
fi
