# Test cluster setup

10.66.66.0/28

5-6-7-8

| IP | Hostname |
| --- | --- |
| 10.66.66.5 | k8s-node-5.milkywaygalaxy.be |
| 10.66.66.6 | k8s-node-6.milkywaygalaxy.be |
| 10.66.66.7 | k8s-node-7.milkywaygalaxy.be |
| 10.66.66.8 | k8s-node-8.milkywaygalaxy.be |


## Normal cluster:

| node | CPU | CORES | RAM |
| --- | --- | --- | --- |
| master | 1 | 2 | 5 GB |
| worker 1 | 1 | 2 | 5 GB |
| worker 2 | 1 | 2 | 5 GB |

> - 3 CPU
> - 6 cores
> - 15 GB RAM


## HA normal cluster:

| node | CPU | CORES | RAM |
| --- | --- | --- | --- |
| master 1 | 1 | 2 | 4 GB |
| master 2 | 1 | 2 | 4 GB |
| master 3 | 1 | 2 | 4 GB |
| worker 1 | 1 | 2 | 6 GB |

> - 4 CPU
> - 8 cores
> - 18 GB RAM

--- 

## Setup

### 1) Create images

```sh
# Kickstart story !!! DO THIS ON CENTOS MANAGEMENT VM !!!

# create dir
mkdir /kickstart
cd /kickstart

# clone project
git clone git@gitlab.com:milkywaygalaxy/kickstart/galaxyos.git

# script prep
chmod +x *.py
mkdir -p /var/log/kickstart/
mkdir -p {official-images,mnt/source-iso}
yum install -y createrepo

# create images (3 masters, 1 worker)
for i in {5..8}
do
    ./generate_galaxyos_iso.py \
        --source_iso=CentOS-7-x86_64-Minimal-1908.iso \
        --current_os=centos \
        --name=k8s-node-$i \
        --ip=10.66.66.$i \
        --netmask=255.255.255.240 \
        --gateway=10.66.66.1 \
        --nic=ens18 \
        --disk=sda \
        --nameservers=10.66.66.1,213.133.98.98,213.133.99.99,213.133.100.100 \
        --hostname=k8s-node-$i.milkywaygalaxy.be
done
```

### 2) Install virtual machines with created images

- Create image
- Create VM
  - snapshot VM before install
- Install VM with iso
  - Test network connectivity
  - Test DNS
    - Snapshot VM after clean install

## Ansible

```sh
# syntax check
ansible-playbook k8s-playbook.yml --syntax-check -i k8s-cluster/inventory

# run playbook on servers
ansible-playbook -i k8s-cluster/inventory -u jorik --ask-become-pass k8s-playbook.yml 
```