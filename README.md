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

## Client Access

```
# 1. login bash shell
./run.sh shell

# 2. execute hadoop command
./run.sh hadoop <command>

# 3. run mapreduce pi example
./run.sh example
```

