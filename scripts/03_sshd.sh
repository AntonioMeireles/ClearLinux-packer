#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

{
	echo 'UseDNS no'
	echo 'PubkeyAuthentication yes'
	echo 'PermitEmptyPasswords no'
	echo 'PasswordAuthentication no'
	echo 'PermitRootLogin no'
	echo 'AuthorizedKeysFile %h/.ssh/authorized_keys'
} > /etc/ssh/sshd_config

