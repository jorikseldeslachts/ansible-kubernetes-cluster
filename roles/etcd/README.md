# ETCD


## About
An Ansible role to install a HA Etcd cluster for Kubernetes.
This role follows instructions of ["kubernetes the hard way reworked"](https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md) by "mmumshad":


## Documentation
- [etcd.io](https://etcd.io/)
- [Raft Algorithm explained with an animation](http://thesecretlivesofdata.com/raft/)
- [How does Etcd work?](https://medium.com/better-programming/a-closer-look-at-etcd-the-brain-of-a-kubernetes-cluster-788c8ea759a5)


## Troubleshooting and checking
```sh
# set version
ETCDCTL_API=3

# list member, show leader
etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/ca.crt \
    --cert=/etc/etcd/etcd-server.crt \
    --key=/etc/etcd/etcd-server.key \
    -w table member list

# status endpoint
etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/ca.crt \
    --cert=/etc/etcd/etcd-server.crt \
    --key=/etc/etcd/etcd-server.key \
    -w table endpoint status

# check health
etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/ca.crt \
    --cert=/etc/etcd/etcd-server.crt \
    --key=/etc/etcd/etcd-server.key \
    -w table endpoint health
```

Results in:
```sh
+------------------+---------+------------+-------------------------+-------------------------+------------+
|        ID        | STATUS  |    NAME    |       PEER ADDRS        |      CLIENT ADDRS       | IS LEARNER |
+------------------+---------+------------+-------------------------+-------------------------+------------+
| 52079981efc7c62a | started | k8s-node-2 | https://10.20.0.22:2380 | https://10.20.0.22:2379 |      false |
| 5ac1d229362f0603 | started | k8s-node-1 | https://10.20.0.21:2380 | https://10.20.0.21:2379 |      false |
| b380a8cd7425a45c | started | k8s-node-3 | https://10.20.0.23:2380 | https://10.20.0.23:2379 |      false |
+------------------+---------+------------+-------------------------+-------------------------+------------+

+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|        ENDPOINT        |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://127.0.0.1:2379 | 5ac1d229362f0603 |  3.4.10 |  2.3 MB |      true |      false |      4309 |      13081 |              13081 |        |
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+

+------------------------+--------+-------------+-------+
|        ENDPOINT        | HEALTH |    TOOK     | ERROR |
+------------------------+--------+-------------+-------+
| https://127.0.0.1:2379 |   true | 10.331258ms |       |
+------------------------+--------+-------------+-------+
```