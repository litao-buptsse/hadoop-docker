#!/bin/bash

rm -fr conf/master*
rm -fr conf/slave
rm -fr conf/.temp

mkdir -p conf/.temp
cp -r conf/template/hadoop_conf_template conf/.temp/hadoop_conf
cp -r conf/template/zookeeper_conf_template conf/.temp/zookeeper_conf

grep ^master conf/cluster_topology.txt | while read line; do
  master=`echo $line | awk -F"=" '{print $1}'`
  host=`echo $line | awk -F"=" '{print $2}'`

  sed -i "s/\${$master}/$host/g" conf/.temp/zookeeper_conf/zoo.cfg
  sed -i "s/\${$master}/$host/g" conf/.temp/hadoop_conf/core-site.xml
  sed -i "s/\${$master}/$host/g" conf/.temp/hadoop_conf/hdfs-site.xml
  sed -i "s/\${$master}/$host/g" conf/.temp/hadoop_conf/yarn-site.xml
  sed -i "s/\${$master}/$host/g" conf/.temp/hadoop_conf/mapred-site.xml
done

for master in master1 master2 master3 master4; do
  cp -r conf/.temp conf/$master 
done

for master in master1 master2; do
  sed -i "s/\${namespace}/ns1/g" conf/$master/hadoop_conf/hdfs-site.xml
done
for master in master3 master4; do
  sed -i "s/\${namespace}/ns2/g" conf/$master/hadoop_conf/hdfs-site.xml
done

cp -r conf/master1 conf/slave

rm -fr conf/.temp
