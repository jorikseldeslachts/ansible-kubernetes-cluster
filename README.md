# Kubernetes with Ansible

## Usefull links

> [Digitalocean Ansible cluster tutorial](https://www.digitalocean.com/community/tutorials/how-to-create-a-kubernetes-cluster-using-kubeadm-on-centos-7)

> [Kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

> [Services explained](https://www.youtube.com/watch?v=5lzUpDtmWgM)


## Running order

1) install 3 vms with custom ISO's
2) disable swap
    - comment/delete /etc/fstab/
    - swapoff -a
3) kube-dependencies.yml
4) master.yml
5) workers.yml
6) cockpit.yml

## Custom changes
- updated selinux section
- added jorik user instead of centos user
- open firewalld ports
- added bash completion for kubectl
- changed hostfile

## Usefull commands:

| Explenation | Command |
| --- | --- |
| Lists pods on nodes | kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName --all-namespaces --sort-by=.spec.nodeName | 
| | kubectl cluster-info |
| Allow pods on master | kubectl taint node k8s-host-1.cosmos.milkywaygalaxy.be node-role.kubernetes.io/master:NoSchedule- |
| | |
| | |
| | |
| | |
| | |
| | |
| | |
| | |

## Cockpit

- 1 cockpit GUI for all servers
- [https://k8s-host-1:9090](https://k8s-host-1:9090)