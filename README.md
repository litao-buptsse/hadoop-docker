# Hadoop Docker

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

## Initial Cluster

```
# 1. edit cluster_topoly.txt

# 2. run ./init_cluster.sh
./init_cluster.sh
```

## Start Service

```
# 1. start zk 
```
