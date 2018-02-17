#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

useradd --create-home --user-group --password '$6$rounds=656000$OY1EmeRe9//dqf8D$KRUcAe5ezDDL4hDe7nCGdURxev0jnIpOAAtfFzhPdd9wmNouedwX7EMxUaF16yrxxOUgpQlrpHVsZkIokXDKv0' vagrant

mkdir -p /etc/sudoers.d

echo 'Defaults:vagrant !requiretty' > /etc/sudoers.d/vagrant
echo '#Defaults !visiblepw' >> /etc/sudoers.d/vagrant
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' >> /etc/sudoers.d/vagrant
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/vagrant

chmod 0440 /etc/sudoers.d/vagrant

mkdir -p /home/vagrant/.ssh

curl -o /home/vagrant/.ssh/vagrant https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant
curl -o /home/vagrant/.ssh/vagrant.pub https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub

cat /home/vagrant/.ssh/vagrant.pub >> /home/vagrant/.ssh/authorized_keys

chown -R vagrant:vagrant /home/vagrant/.ssh

chmod 0700 /home/vagrant/.ssh
chmod 0640 /home/vagrant/.ssh/authorized_keys /home/vagrant/.ssh/vagrant.pub
chmod 0600 /home/vagrant/.ssh/vagrant

