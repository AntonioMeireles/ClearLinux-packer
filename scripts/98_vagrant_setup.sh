#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

export VAGRANT_USER="${VAGRANT_USER:-clear}"
export VAGRANT_PASSWORD='$6$rounds=656000$OY1EmeRe9//dqf8D$KRUcAe5ezDDL4hDe7nCGdURxev0jnIpOAAtfFzhPdd9wmNouedwX7EMxUaF16yrxxOUgpQlrpHVsZkIokXDKv0'
export VAGRANT_HOME="/home/${VAGRANT_USER}"
export DOT_SSH="${VAGRANT_HOME}/.ssh"
export KEYS_URL="https://raw.githubusercontent.com/mitchellh/vagrant/master/keys"
export SUDOERS="/etc/sudoers.d/vagrant"

useradd --create-home --user-group --password ${VAGRANT_PASSWORD} "${VAGRANT_USER}"

mkdir -p "$(dirname ${SUDOERS})"

{
	echo "Defaults:${VAGRANT_USER} !requiretty"
	echo '#Defaults !visiblepw'
	echo 'Defaults env_keep += "SSH_AUTH_SOCK"'
	echo "${VAGRANT_USER} ALL=(ALL) NOPASSWD: ALL"
} >> "${SUDOERS}"

chmod -R 0550 "${SUDOERS}"

mkdir -p -m 0700 "${DOT_SSH}"

for f in vagrant{,.pub}
do
	curl -o "${DOT_SSH}/${f}" -sSL "${KEYS_URL}/${f}"
done

cat "${DOT_SSH}/vagrant.pub" >> "${DOT_SSH}/authorized_keys"

chown -R "${VAGRANT_USER}":"${VAGRANT_USER}" "${DOT_SSH}"
chmod 0640 "${DOT_SSH}/authorized_keys" "${DOT_SSH}/vagrant.pub"
chmod 0600 "${DOT_SSH}/vagrant"

{
	echo 'UseDNS no'
	echo 'PubkeyAuthentication yes'
	echo 'PermitEmptyPasswords no'
	echo 'PasswordAuthentication no'
	echo 'PermitRootLogin no'
	echo 'AuthorizedKeysFile %h/.ssh/authorized_keys'
} > /etc/ssh/sshd_config
chmod 0600 /etc/ssh/sshd_config

mkdir -p /etc/tmpfiles.d
touch /etc/tmpfiles.d/clr-power-tweaks.conf

mkdir -p /etc/systemd/network/80-dhcp.network.d
{
	echo "[DHCP]"
	echo "DHCP=ipv4"
	echo "SendHostname=false"
	echo "ClientIdentifier=mac"
} > /etc/systemd/network/80-dhcp.network.d/1stBootFix.conf

{
	echo "[Match]"
	echo "Driver=virtio_net vmxnet3"
	echo "[Link]"
	echo "NamePolicy=path"
} > /etc/systemd/network/10-systemd-net-quirks.link

# workaround https://github.com/systemd/systemd/issues/9682 at all costs
# seems to be a thing with systemd-239 :/
mkdir -p  /etc/systemd/system/systemd-udevd.service.d/
{
	echo "[Service]"
	echo "ExecStartPost=/usr/bin/sleep 5"
} > /etc/systemd/system/systemd-udevd.service.d/fix-iface-rename.conf

clr-boot-manager update

swupd clean

sync
