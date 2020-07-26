# Kubernetes with Ansible


## About


## Documentation
- [Digitalocean Ansible cluster tutorial](https://www.digitalocean.com/community/tutorials/how-to-create-a-kubernetes-cluster-using-kubeadm-on-centos-7)
- [Kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Services explained](https://www.youtube.com/watch?v=5lzUpDtmWgM)


## Ansible
```bash
# copy ssh keys
for i in {24,25,26}
do
    ssh-copy-id root@10.66.66.$i
    ssh-copy-id jorik@10.66.66.$i
    echo "10.66.66.$i done"
done

# remove yum lock if ansible is crashing on a second run
for i in {24,25,26}
do
    ssh root@10.66.66.$i rm -rf /var/run/yum.pid
    ssh root@10.66.66.$i yum clean all
    echo "10.66.66.$i done"
done
```



## Usefukll Kubernetes commands:
| Explenation | Command |
| --- | --- |
| Lists pods on nodes | kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName --all-namespaces --sort-by=.spec.nodeName | 
| | kubectl cluster-info |
| Allow pods on master | kubectl taint node k8s-host-1.cosmos.milkywaygalaxy.be node-role.kubernetes.io/master:NoSchedule- |
| | |





# TODO
- [x] install nginx ingress
  - [ ] Daemonset on each node
- [ ] install test project
- [ ] make /DATA dir
- [ ] storage??
- [x] SET HOSTNAMES IN HOSTFILE!!!! THAT IS WHAT MADE NETWORK FUCKEDUP
- [x] get nodes : register + debug
- [x] print if cni1 is aangemaakt
- [ ] -kubernetes dashboard!
- [x] k8s .bashrc
- [x] blue colors
- [x] bash completion get added every rerun ">>" --> replace with lineinfile
- [ ] k9s
- [ ] octant
- [ ] Loadbalander setup
  - [ ] Nginx.conf
  - [ ] ladbalander.conf
  - [ ] expose API
- [ ] Check to NOT join master/worker if already "ready"
  - [x] k get node k8s-node-5 --no-headers | awk '{ print $1 "," $2 "," $3 }'
- [ ] ELK: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-elasticsearch-fluentd-and-kibana-efk-logging-stack-on-kubernetes



## Contributors
- Jorik Seldeslachts (Main Developer)