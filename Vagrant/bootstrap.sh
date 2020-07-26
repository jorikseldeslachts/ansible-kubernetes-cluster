#!/bin/sh

# This script will try math the VM's with the galaxyos images.
# The galaxyos images are custom CentOS7 based images created by:
# https://gitlab.com/milkywaygalaxy/kickstart/galaxyos


# change ssh to no password
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

# add vagrant user to sudoers
usermod -aG wheel vagrant

# change root password
sudo echo "vagrant" | sudo passwd root

# set prompt colors
echo " ==> Configuring prompt for user root to red ... "
cat <<EOT >> /root/.bashrc

# Shell in kleur (rood):
GREEN='\[\e[01;32m\]'
BLUE='\[\e[01;34m\]'
WHITE='\[\e[01;00m\]'
RED='\[\e[01;31m\]'
PS1="\$RED[\u\$BLUE@\$RED\h\$BLUE \w\$RED]\$WHITE\$ "
EOT

# set some aliases
echo " ==> Configuring customg aliases ... "
cat <<EOT >> /etc/profile

# Customg aliases
alias rm='rm -i'
alias ll='ls -lAh --color=auto'
alias tree='tree -C'
EOT

# disable bell
echo " ==> Disabeling bell sounds ... "
echo 'set bell-style none' >> ~/.inputrc
echo "blacklist pcspkr" >> /etc/modprobe.d/blacklist.conf

# install some packages
echo -e "\n ==> Installing packages ... \n"
yum install -y \
    epel-release \
    bind-utils \
    yum-utils \
    nfs-utils
echo " ==> Installing done."

echo " ==> Provisioning script done, ready to start installing Kubernetes."