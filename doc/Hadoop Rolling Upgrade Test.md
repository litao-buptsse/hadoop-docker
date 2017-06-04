[TOC]

# 一、搭建cdh5.3.2集群

## 1. 搭建cdh5.3.2集群 - HDFS

### 步骤
1. ./run.sh 2.5.0-cdh5.3.2 zookeeper (master1, master2, master3)
2. ./run.sh 2.5.0-cdh5.3.2 journalnode (master1, master2, master3)
3. ./run.sh 2.5.0-cdh5.3.2 formatNamenode (master1, master3)
4. ./run.sh 2.5.0-cdh5.3.2 namenode (master1, master3)
5. ./run.sh 2.5.0-cdh5.3.2 bootstrapStandby (master2, master4)
6. ./run.sh 2.5.0-cdh5.3.2 namenode (master2, master4)
7. ./run.sh 2.5.0-cdh5.3.2 formatZkfc (master1, master3)
8. ./run.sh 2.5.0-cdh5.3.2 zkfc (master1, master2, master3, master4)
9. ./run.sh 2.5.0-cdh5.3.2 datanode (slaves)

### 测试点
1. 测试HDFS基本的操作 (cdh5.3.2客户端)
    1. ./run.sh 2.5.0-cdh5.3.2 hadoop fs -mkdir hdfs://ns1/logdata
    2. mkdir -p mnt; cp README.md mnt
    3. ./run.sh 2.5.0-cdh5.3.2 hadoop fs -put /search/mnt/README.md /logdata
    4. ./run.sh 2.5.0-cdh5.3.2 hadoop fs -cat /logdata/README.md

## 2. 搭建cdh5.3.2集群 - YARN

### 步骤
1. ./run.sh 2.5.0-cdh5.3.2 resourcemanager (master1, master2)
2. ./run.sh 2.5.0-cdh5.3.2 timelineserver (master3)
3. ./run.sh 2.5.0-cdh5.3.2 historyserver (master4)
4. ./run.sh 2.5.0-cdh5.3.2 nodemanager (slaves)

### 测试点
1. 跑通MapReduce Example (cdh5.3.2客户端)
    1. ./run.sh 2.5.0-cdh5.3.2 pi
    2. ./run.sh 2.5.0-cdh5.3.2 wordcount
2. MR任务日志可以查看

# 二. 滚动升级至cdh5.10.0

## 1. 升级NameNode - ns1

### 步骤
1. ./run.sh 2.5.0-cdh5.3.2 hdfs dfsadmin -Dfs.defaultFS=hdfs://ns1 -rollingUpgrade prepare (开始生成rollback fsimage)
2. ./run.sh 2.5.0-cdh5.3.2 hdfs dfsadmin -Dfs.defaultFS=hdfs://ns1 -rollingUpgrade query (查询状态，直至出现"Proceed with rolling upgrade"，表明rollback fsimage创建完毕)
3. ./run.sh 2.6.0-cdh5.10.0 namenode -rollingUpgrade started (升级重启standby namenode)
4. ./run.sh 2.6.0-cdh5.10.0 namenode -rollingUpgrade started (升级重启active namenode)

### 测试点
1. 确保cdh5.3.2的datanode能够向cdh5.10.0的namenode汇报心跳
2. hdfs基本操作执行成功 (cdh5.3.2客户端)
3. mr任务跑成功 (cdh5.3.2客户端)
4. MR任务日志可以查看

## 2. 升级NameNode - ns2 (同理)

## 3. 升级2台Slave节点的DataNode和NodeManager

### 步骤
1. ./run.sh 2.5.0-cdh5.3.2 hdfs dfsadmin -shutdownDatanode <DATANODE_HOST:50020> upgrade (停掉Datanode)
2. ./run.sh 2.5.0-cdh5.3.2 hdfs dfsadmin -getDatanodeInfo <DATANODE_HOST:50020> (确保DataNode停掉)
3. ./run.sh 2.6.0-cdh5.10.0 datanode (升级重启datanode)
4. ./run.sh 2.6.0-cdh5.10.0 nodemanager (升级重启nodemanager)

### 测试点
1. 确保cdh5.10.0的datanode能够向cdh5.10.0的namenode汇报心跳
2. 确保cdh5.10.0的nodemanager能够向cdh5.3.2的resourcemanager汇报心跳
3. hdfs基本操作执行成功 (cdh5.3.2客户端)
4. mr任务跑成功 (cdh5.3.2客户端)（注：需测试AM与Map/Reduce跨不同版本的NodeManner的情况）
5. nodemanager升级重启后，该节点上之前运行的任务不挂掉
6. MR任务日志可以查看

## 4. 升级所有Slave节点的DataNode和NodeManager (同理)

## 5. 升级resourcemanager

### 步骤
1. ./run.sh 2.6.0-cdh5.10.0 resourcemanager (升级重启standby resourcemanager)
2. ./run.sh 2.6.0-cdh5.10.0 resourcemanager (升级重启active resourcemanager)

### 测试点
1. 确保cdh5.10.0的nodemanager能够向cdh5.10.0的resourcemanager汇报心跳
2. mr任务跑成功 (cdh5.3.2客户端)
3. resourcemanager切换后，之前运行的任务不挂掉

## 6. 升级timelineserver、historyserver

### 步骤
1. ./run.sh 2.6.0-cdh5.10.0 timelineserver (升级重启timelineserver)
2. ./run.sh 2.6.0-cdh5.10.0 historyserver (升级重启historyserver)

### 测试点
1. mr任务跑成功 (cdh5.3.2与cdh5.10.0客户端)
2. MR任务日志可以查看

## 7. 提交更新

### 步骤
1. ./run.sh 2.6.0-cdh5.10.0 hdfs dfsadmin -Dfs.defaultFS=hdfs://ns1 -rollingUpgrade finalize
2. ./run.sh 2.6.0-cdh5.10.0 hdfs dfsadmin -Dfs.defaultFS=hdfs://ns2 -rollingUpgrade finalize

### 测试点
1. hdfs基本操作执行成功 (cdh5.3.2与cdh5.10.0客户端)
2. mr任务跑成功 (cdh5.3.2与cdh5.10.0客户端)
3. 之前运行的任务不挂掉
4. MR任务日志可以查看
