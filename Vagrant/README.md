# Vagrant

## About
Set up a local test environment to test the Ansible playbooks.


## Usage

### 1) Install vagrant plugin for env vars
For this setup we make use of a `.env` file to configure environment vars for the `Vagrantfile`.
To be able to use this you have to install a plugin called `vagrant-env` as described [here](https://www.nickhammond.com/configuring-vagrant-virtual-machines-with-env/).

```sh
# Install
vagrant plugin install vagrant-env

# Check if successfully installed
vagrant plugin list
```

### 2) Configure environment variables
After that you can configure the following environment variables in [`.env`](./.env):
```sh
# Amount of virtual machines to spin up
K8S_NODE_COUNT=3

# The domain name used for the hostnames
K8S_NODE_DOMAIN=galaxy.local

# Memory and CPU resources
K8S_NODE_CPUS=1
K8S_NODE_MEMORY=1024
```

### 3) Start virtual machines
```sh
# Start the test environment
vagrant up
```

### 4) Cleanup
```sh
# Destroy all the virtual machines
vagrant destroy -f
```


## Known Issues
- This is only for Windows users using WSL. It seems like WSL sometimes messes up the virtual machines. Therefor it is advised to run the `vagrant up` command through `Powershell`.


## Contributors
- Jorik Seldeslachts (Main Developer)