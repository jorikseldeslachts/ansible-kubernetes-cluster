# Vagrant

For this setup we make use of a `.env` file to configure environment vars for the `Vagrantfile`.
To be able to use this you have to install a plugin called `vagrant-env` as described [here](https://www.nickhammond.com/configuring-vagrant-virtual-machines-with-env/).

```sh
vagrant plugin install vagrant-env
```

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