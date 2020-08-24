# Kubernetes with Ansible


## About
This project can be used to setup a `Kubernetes` cluster with HA control panes and HA Etcd cluster using `Ansible`.
It provides three playbooks:

| Playbook | Description |
|---|---|
| [`playbook-k8s-all.yml`](./playbook-k8s-all.yml)                               | Complete Kubernetes cluster installation. |
| [`playbook-kubeadm-add-new-master.yml`](./playbook-kubeadm-add-new-master.yml) | Add new master(s) to an existing cluster. |
| [`playbook-kubeadm-add-new-worker.yml`](./playbook-kubeadm-add-new-worker.yml) | Add new worker(s) to an existing cluster. |


## Requirements
- Ansible 2.8
- Virtual Machines with `CentOS8` ready when not using [`Vagrant`](./Vagrant/)


## Ansible
Before running the playbooks you need to copy your SSH key to the remote servers.
```sh
# copy ssh keys
$ for i in {21,22,23,24}
  do
      sshpass -p "vagrant" ssh-copy-id vagrant@172.16.88.$i
      sshpass -p "vagrant" ssh-copy-id root@172.16.88.$i
      echo "172.16.88.$i done"
  done
```

You will need to prepare an inventory file for Ansible. There are examples you can copy and edit in the [inventories/examples](./inventories/examples/) folder.
Place them in the `inventories` folder and you are good to go.

After that export the `Ansible` configuration and you are ready to run the playbooks.
```sh
$ export ANSIBLE_CONFIG=./ansible.cfg
```

It is advised to run a syntax check to be sure all needed variabled are filled in and there are no syntax errors.
```sh
# Run a syntax check
$ ansible-playbook playbook-k8s-all.yml \
  -i inventories/vagrant-full-install.inv \
  -u vagrant \
  --ask-become-pass \
  --syntax-check
```

Install the playbooks:
- Complete Kubernetes cluster installation:
  ```sh
  # Complete installation
  $ ansible-playbook \
      -i inventories/vagrant-full-install.inv \
      -u vagrant \
      --ask-become-pass \
      playbook-k8s-all.yml
  ```
- Add new master(s) to an existing cluster:
  ```sh
  # Add masters
  $ ansible-playbook \
      -i inventories/vagrant-add-master.inv \
      -u vagrant \
      --ask-become-pass \
      playbook-kubeadm-add-new-master.yml
  ```
- Add new worker(s) to an existing cluster:
  ```sh
  # Add workers
  $ ansible-playbook \
      -i inventories/vagrant-add-worker.inv \
      -u vagrant \
      --ask-become-pass \
      playbook-kubeadm-add-new-worker.yml
  ```



## Known Issues
- When running the Ansible playbook using `WSL` you might get the following warning:
  > [WARNING] Ansible is being run in a world writable directory, ignoring it as an ansible.cfg source. For more information see https://docs.ansible.com/ansible/devel/reference_appendices/config.html#cfg-in-world-writable-dir
  This can be solved by the following command:
  ```sh
  export ANSIBLE_CONFIG=./ansible.cfg
  ```


## TODO
- [ ] Check to NOT join master/worker if already "Ready"
- [ ] Taint master to allow running pods on the master node in "init-first-master" role
- [ ] Support for [`Calico`](https://docs.projectcalico.org/) CNI
- [ ] Add the option to add new nodes to the etcd cluster when adding masters


## Contributors
- Jorik Seldeslachts