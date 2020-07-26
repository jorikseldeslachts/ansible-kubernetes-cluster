#!/bin/sh

# This script will try math the VM's with the galaxyos images.
# The galaxyos images are custom CentOS7 based images created by:
# https://gitlab.com/milkywaygalaxy/kickstart/galaxyos


#############################################################
# SET PASSWORDS FOR SSH AND ANSIBLE
#############################################################
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
usermod -aG wheel vagrant


#############################################################
# SET PROMPT STYLE COLORS
#############################################################
echo " ==> Configuring prompt for user root to red ... "
cat <<EOT >> /root/.bashrc

# Shell in kleur (rood):
GREEN='\[\e[01;32m\]'
BLUE='\[\e[01;34m\]'
WHITE='\[\e[01;00m\]'
RED='\[\e[01;31m\]'
PS1="\$RED[\u\$BLUE@\$RED\h\$BLUE \w\$RED]\$WHITE\$ "
EOT

#############################################################
# CUSTOM ALIASES
#############################################################
echo " ==> Configuring customg aliases ... "
cat <<EOT >> /etc/profile

# Customg aliases
alias rm='rm -i'
alias ll='ls -lAh --color=auto'
alias tree='tree -C'
EOT

#############################################################
# DISABLE BELL
#############################################################
echo " ==> Disabeling bell sounds ... "
echo 'set bell-style none' >> ~/.inputrc
echo "blacklist pcspkr" >> /etc/modprobe.d/blacklist.conf

#############################################################
# PACKAGE LISTS
#############################################################

# Install
echo -e "\n ==> Installing packages ... \n"
yum install -y \
    epel-release \
    bind-utils \
    yum-utils \
    nfs-utils
echo " ==> Installing done."

echo " ==> Provisioning script done, ready to start installing Kubernetes."