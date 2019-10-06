# Kubernetes with Ansible

## Setup om KVM

- [KVM cheat sheet](https://www.techotopia.com/index.php/Installing_a_KVM_Guest_OS_from_the_Command-line_(virt-install))

```bash
# create disks / volumes
cd /var/lib/libvirt/filesystems
for i in {4..6}
do
    qemu-img create -f qcow2 /var/lib/libvirt/filesystems/k8s-host-$i.qcow2 50G
done

# create vm's --> voor help: --network=?\
for i in {4..6}
do
    virt-install \
        --name=k8s-host-$i \
        --os-variant=centos7.0 \
        --vcpus=2 \
        --memory=6144 \
        --cdrom=/var/lib/libvirt/images/k8s-host-$i.iso \
        --disk vol=galaxy_vms/k8s-host-$i.qcow2 \
        --network network:galaxy_net_lan \
        --vnc
done

# snapshots
for i in {4..6}
do
    virsh snapshot-create-as \
        --domain k8s-host-$i \
        --name k8s-host-$i-clean \
        --description "Clean before ansible/k8s"
done

# check snapshots
for i in {4..6}
do
    virsh snapshot-list --domain k8s-host-$i
done

# revert
for i in {4..6}
do
    virsh snapshot-revert k8s-host-$i k8s-host-$i-clean
done

```

## Ansible

```bash
# install pip
sudo apt install -y python-pip

# install requirements
sudo pip install -r requirements.txt

# ansible version should be >=2.8
ansible --version

# ssh keys
for i in {24,25,26}
do
    ssh-copy-id root@10.66.66.$i
    ssh-copy-id jorik@10.66.66.$i
    echo "10.66.66.$i done"
done

# update && upgrade
for i in {24,25,26}
do
    ssh root@10.66.66.$i \
        yum update -y && \
        yum upgrade -y && \
        yum clean all
    echo "10.66.66.$i done"
done
  
# remove yum lock if ansible crashing
for i in {24,25,26}
do
    ssh root@10.66.66.$i rm -rf /var/run/yum.pid
    ssh root@10.66.66.$i yum clean all
    echo "10.66.66.$i done"
done

# reboot
for i in {4,5,6}
do
    ssh root@10.66.66.2$i hostnamectl set-hostname k8s-host-$i.milkywaygalaxy.be
    ssh root@10.66.66.2$i reboot -h now
    echo "Rebooting 10.66.66.$i ..."
done


```




## Usefull links

> [Digitalocean Ansible cluster tutorial](https://www.digitalocean.com/community/tutorials/how-to-create-a-kubernetes-cluster-using-kubeadm-on-centos-7)

> [Kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

> [Services explained](https://www.youtube.com/watch?v=5lzUpDtmWgM)


## Running order

1) install 3 vms with custom ISO's
2) docker.yml
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


## Cockpit

- 1 cockpit GUI for all servers
- [https://k8s-host-1:9090](https://k8s-host-1:9090)


## Router
```bash
# ISO
./generate_galaxyos_iso.py \
    --source_iso=CentOS-7-x86_64-Minimal-1810.iso \
    --current_os=centos \
    --name=skygate \
    --ip=10.66.66.9 \
    --netmask=255.255.255.224 \
    --gateway=10.66.66.2 \
    --nic=ens3 \
    --disk=vda \
    --nameservers=213.133.98.98,213.133.99.99,213.133.100.100 \
    --hostname=skygate.milkywaygalaxy.be

# volume
qemu-img create -f qcow2 /var/lib/libvirt/filesystems/skygate.qcow2 30G
qemu-img create -f qcow2 /var/lib/libvirt/filesystems/kubegate.qcow2 50G

# VM
virt-install \
    --name=skygate \
    --os-variant=centos7.0 \
    --vcpus=1 \
    --memory=6144 \
    --cdrom=/var/lib/libvirt/images/skygate.iso \
    --disk vol=galaxy_vms/skygate.qcow2 \
    --network network:galaxy_net_lan \
    --vnc

virt-install \
    --name=kubegate \
    --os-variant=freebsd8 \
    --vcpus=1 \
    --memory=6144 \
    --cdrom=/var/lib/libvirt/images/pfSense-CE-2.4.4-RELEASE-p1-amd64.iso \
    --disk vol=galaxy_vms/kubegate.qcow2 \
    --vnc


# add nic
virsh attach-interface  \
    --source galaxy_net_lan  \
    --domain kubegate  \
    --type network   \
    --model virtio  \
    --config  \
    --live

virsh attach-interface \
    --domain kubegate \
    bridge br29 \
    --model virtio \
    --mac 00:50:56:15:24:da \
    --config \
    --live

    


```