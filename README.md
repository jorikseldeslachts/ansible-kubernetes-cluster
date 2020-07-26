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

```sh
# syntax check
ansible-playbook k8s-playbook.yml --syntax-check -i k8s-cluster/inventory

# run playbook on servers
ansible-playbook -i k8s-cluster/inventory -u vagrant --ask-become-pass k8s-playbook.yml
```

# Playbook

```sh
# syntax check
export ANSIBLE_CONFIG=./ansible.cfg
ansible-playbook -i inventories/inventory-full-install playbooks/k8s-all.yml --syntax-check


# full install
git pull origin feature/split_in_seperate_roles; \
ansible-playbook -i inventories/inventory-full-install -u jorik --ask-become-pass playbooks/k8s-all.yml

# add master
# git pull origin feature/split_in_seperate_roles; \
# ansible-playbook -i inventories/inventory-add-master -u jorik --ask-become-pass k8s-playbook.yml


# add worker
# git pull origin feature/split_in_seperate_roles; \
# ansible-playbook -i inventories/inventory-add-worker -u jorik --ask-become-pass k8s-playbook.yml

```


## Useful Kubernetes commands:
| Explenation | Command |
| --- | --- |
| Lists pods on nodes | kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName --all-namespaces --sort-by=.spec.nodeName | 
| | kubectl cluster-info |
| Allow pods on master | kubectl taint node k8s-host-1.cosmos.milkywaygalaxy.be node-role.kubernetes.io/master:NoSchedule- |
| | |


```
## Known Issues
- When running the Ansible playbook using `WSL` you might get the following warning:
  > [WARNING] Ansible is being run in a world writable directory (/mnt/d/Documents/projects/kubernetes-cluster-hetzner), ignoring it as an ansible.cfg source. For more information see https://docs.ansible.com/ansible/devel/reference_appendices/config.html#cfg-in-world-writable-dir

  This can be solved by the following command:
  ```sh
  export ANSIBLE_CONFIG=./ansible.cfg
  ```


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


## Contributors
- Jorik Seldeslachts (Main Developer)