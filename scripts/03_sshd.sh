#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace


sed -i '/PermitRootLogin yes/d' /etc/ssh/sshd_config

echo 'UseDNS no' >> /etc/ssh/sshd_config
echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config
echo 'AuthorizedKeysFile %h/.ssh/authorized_keys' >> /etc/ssh/sshd_config
echo 'PermitEmptyPasswords no' >> /etc/ssh/sshd_config
echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config

systemctl enable sshd.socket

