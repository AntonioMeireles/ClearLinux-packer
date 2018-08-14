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
	echo 'Ciphers +aes128-cbc'
} > /etc/ssh/sshd_config

