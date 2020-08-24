# Vagrant

## About
Set up a local test environment to test the Ansible playbooks.


## Network map
```sh
                                              ___________________
                                             |                   |
                                             | Host: k8s-node-1  |
                                       +-----| Type: K8S Master  |-----+
                                       |     | IP: 172.16.88.21  |     |
                                       |     |___________________|     |
                                       |                               |
             ____________________      |      ___________________      |
            |                    |     |     |                   |     |
            | Host: k8s-nginx-lb |     |     | Host: k8s-node-2  |     |
Laptop -----| Type: Loadbalancer |-----+-----| Type: K8S Master  |-----|
            | IP: 172.16.88.20   |     |     | IP: 172.16.88.22  |     |
            |____________________|     |     |___________________|     |
                                       |                               |
                                       |      ___________________      |
                                       |     |                   |     |
                                       |     | Host: k8s-node-3  |     |
                                       +-----| Type: K8S Master  |-----|
                                             | IP: 172.16.88.23  |     |
                                             |___________________|     |
                                                                       |
                                              ___________________      |
                                             |                   |     |
                                             | Host: k8s-node-4  |     |
                                             | Type: K8S Worker  |-----+
                                             | IP: 172.16.88.24  |
                                             |___________________|

```


## Usage

### 1) Configure servers
You can configure the desired servers in the [`vagrant_servers.yaml`](./vagrant_servers.yaml) file. It is just simple `yaml` format that will be loaded into the [`Vagrantfile`](./Vagrantfile). The file can be configured as follow:
```yaml
---
debug: true
servers:
  - name: server-1
    box: geerlingguy/centos7
    box_version: 1.2.21
    ip: 192.168.1.11
    cpus: 1
    memory: 512
  - name: server-2
    box: geerlingguy/centos7
    box_version: 1.2.21
    ip: 192.168.1.12
    cpus: 2
    memory: 1024
```
Note that the first IPv4 address in the range might be used by the router so avoid using that.
When `debug` is set to `true` the [`vagrant_servers.yaml`](./vagrant_servers.yaml) will print out the server configuration when using the `vagrant` command.

### 2) Start virtual machines
```sh
# Start the test environment
vagrant up --parallel --color --timestamp

# Check
vagrant status
vagrant global-status
```
```sh
# lb logs
tail -f /var/log/nginx/*/*
```


### 3) Snapshots
It is advised to save a snapshot before running the Ansible playbooks. This way you can simply reverse the snapshot instead of building new virtual machines for every test run.
```sh
# Save snapshot
vagrant snapshot save clean-install
vagrant snapshot save ready-for-k8s

# List snapshots
vagrant snapshot list

# Restore snapshot
vagrant snapshot restore clean-install
vagrant snapshot restore ready-for-k8s
```

### 4) Cleanup
```sh
# Destroy all the virtual machines
vagrant destroy --force --parallel --color --timestamp
```


## Known Issues
- This is only for Windows users using WSL. It seems like WSL sometimes messes up the virtual machines. Therefor it is advised to run the `vagrant up` command through `Powershell`.


## Contributors
- Jorik Seldeslachts (Main Developer)