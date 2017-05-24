#!/bin/bash

rm -fr conf/client
rm -fr conf/.temp

mkdir -p conf/.temp conf/client
cp -r conf/template/hadoop_server_conf_template conf/.temp/hadoop_conf
cp -r conf/template/zookeeper_conf_template conf/.temp/zookeeper_conf
cp -r conf/template/hadoop_client_conf_template conf/client/hadoop_conf
cp -r conf/template/zookeeper_conf_template conf/client/zookeeper_conf

grep ^master conf/cluster_topology.txt | while read line; do
  master=`echo $line | awk -F"=" '{print $1}'`
  host=`echo $line | awk -F"=" '{print $2}'`

  sed -i "s/\${$master}/$host/g" conf/.temp/zookeeper_conf/zoo.cfg conf/client/zookeeper_conf/zoo.cfg
  sed -i "s/\${$master}/$host/g" conf/.temp/hadoop_conf/core-site.xml conf/client/hadoop_conf/core-site.xml
  sed -i "s/\${$master}/$host/g" conf/.temp/hadoop_conf/hdfs-site.xml conf/client/hadoop_conf/hdfs-site.xml
  sed -i "s/\${$master}/$host/g" conf/.temp/hadoop_conf/yarn-site.xml conf/client/hadoop_conf/yarn-site.xml
  sed -i "s/\${$master}/$host/g" conf/.temp/hadoop_conf/mapred-site.xml conf/client/hadoop_conf/mapred-site.xml
done

for master in master1 master2 master3 master4; do
  mkdir -p conf/$master/hadoop_conf; rm -fr conf/$master/hadoop_conf/*
  mkdir -p conf/$master/zookeeper_conf; rm -fr conf/$master/zookeeper_conf/*
  cp -r conf/.temp/hadoop_conf/* conf/$master/hadoop_conf
  cp -r conf/.temp/zookeeper_conf/* conf/$master/zookeeper_conf
done

for master in master1 master2; do
  sed -i "s/\${namespace}/ns1/g" conf/$master/hadoop_conf/hdfs-site.xml
done
for master in master3 master4; do
  sed -i "s/\${namespace}/ns2/g" conf/$master/hadoop_conf/hdfs-site.xml
done

mkdir -p conf/slave/hadoop_conf; rm -fr conf/slave/hadoop_conf/*
mkdir -p conf/slave/zookeeper_conf; rm -fr conf/slave/zookeeper_conf/*
cp -r conf/master1/hadoop_conf/* conf/slave/hadoop_conf
cp -r conf/master1/zookeeper_conf/* conf/slave/zookeeper_conf

rm -fr conf/.temp
