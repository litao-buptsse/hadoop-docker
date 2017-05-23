# Hadoop Docker - Quick Setup Hadoop Cluster

[TOC]

## Build Docker

```
./build.sh <branch>
```

## Cluster Topology

### Master Nodes

| Node  | HDFS Module        | YARN Module | HBase Module | Zookeeper Module |
| ----- | ------------------ | ----------- | ------------ | ---------------- |
| node1 | NN1(ns1)、ZKFC1、JN1 | RM1         | HM1          | ZK1              |
| node2 | NN2(ns1)、ZKFC2、JN2 | RM2         | HM2          | ZK2              |
| node3 | NN3(ns2)、ZKFC3、JN3 | TS          | HM3          | ZK3              |
| node4 | NN4(ns2)、ZKFC4     | HS          |              |                  |

### Slave Nodes

| Node | HDFS Module | YARN Module | HBase Module |
| ---- | ----------- | ----------- | ------------ |
| *    | DN          | NM          | RS           |



## Create Cluster

### Initial Config

```
# 1. config the cluster topology, conf/cluster_topoly.txt (masters, slaves)

# 2. config the hadoop version, conf/VERSION (masters, slaves)
```

### Start Module

```
# 1. start zk (master1, master2, master3)
./run.sh zookeeper

# 2. start jn (master1, master2, master3)
./run.sh journalnode

# 3. format namenode (master1, master3)
./run.sh formatNamenode

# 4. start active namenode (master1, master3)
./run.sh namenode

# 5. bootstrap standby namenode (master2, master4)
./run.sh bootstrapStandby

# 6. start standby namenode (master2, master4)
./run.sh namenode

# 7. format zkfc (master1, master3)
./run.sh formatZkfc

# 8. start zkfc (master1, master2, master3, master4)
./run.sh zkfc

# 9. start datanode (slaves)
./run.sh datanode

# 10. start resourcemanager (master1, master2)
./run.sh resourcemanager

# 11. start timelineserver (master3)
./run.sh timelineserver

# 12. start historyserver (master4)
./run.sh historyserver

# 13. start nodemanager (slaves)
./run.sh nodemanager
```

## Rolling Upgrade

### Initial Config

```
# config the new hadoop version, conf/VERSION (masters, slaves)
```

### Upgrade HDFS NameNode

```
# 1. 升级第一组HDFS NameNode
## 1.1 创建rollback fsimage
./run.sh hdfs dfsadmin -Dfs.defaultFS=hdfs://ns1 -rollingUpgrade prepare (client)
## 1.2 查询状态，直至出现"Proceed with rolling upgrade"，表明rollback fsimage创建完毕
./run.sh hdfs dfsadmin -Dfs.defaultFS=hdfs://ns1 -rollingUpgrade query (client)
## 1.3 停掉Standby NameNode，更新至新版本，使用-rollingUpgrade started选项重启 (注：在第一步Initial Config中，已经更新过VERSION文件；./run.sh namenode会首先kill掉当前namenode，然后拉去VERSION文件所配hadoop版本的最新docker镜像，然后启动NameNode)
./run.sh namenode -rollingUpgrade started (master2)
## 1.4 从Standby至Active做一次Failover切换，停掉Active NameNode，更新至新版本，使用-rollingUpgrade started选项重启
./run.sh namenode -rollingUpgrade started (master1)

# 2. 同理，升级第二组HDFS NameNode
```

### Upgrade HDFS DataNode

```
1. 选取一台DataNode节点
## 1.1 使用hdfs dfsadmin -shutdownDatanode停掉DataNode
./run.sh hdfs dfsadmin -shutdownDatanode <DATANODE_HOST:50010> upgrade
## 1.2 使用hdfs dfsadmin -getDatanodeInfo检测DataNode已经停掉
./run.sh hdfs dfsadmin -getDatanodeInfo <DATANODE_HOST:50010>
## 1.3 停掉DataNode，更新至新版本,并重新启动
./run.sh datanode

2. 逐步扩大DataNode升级范围直至全部升级完毕
```

### Finalize Rolling Upgrade

```
./run.sh hdfs dfsadmin -rollingUpgrade finalize"
```

## Client Access

```
# 1. login bash shell
./run.sh shell

# 2. execute hadoop command
./run.sh hadoop <command>

# 3. run mapreduce pi example
./run.sh example
```

