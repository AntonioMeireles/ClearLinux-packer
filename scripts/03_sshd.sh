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

mkdir -p /etc/systemd/system/sshd.socket.d
{
	echo '[Socket]'
	echo 'ListenStream='
	echo 'ListenStream=22'
	echo 'Accept=yes'
	echo 'FreeBind=true'
} > /etc/systemd/system/sshd.socket.d/10-freebind.conf

systemctl enable sshd.socket

