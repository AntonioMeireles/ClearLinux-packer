#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

export VAGRANT_USER="${VAGRANT_USER:-clear}"
export VAGRANT_PASSWORD='$6$rounds=656000$OY1EmeRe9//dqf8D$KRUcAe5ezDDL4hDe7nCGdURxev0jnIpOAAtfFzhPdd9wmNouedwX7EMxUaF16yrxxOUgpQlrpHVsZkIokXDKv0'
export VAGRANT_HOME="/home/${VAGRANT_USER}"
export DOT_SSH="${VAGRANT_HOME}/.ssh"
export KEYS_URL="https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/"
export SUDOERS="/etc/sudoers.d/vagrant"

useradd --create-home --user-group --password ${VAGRANT_PASSWORD} "${VAGRANT_USER}"

mkdir -p "$(dirname ${SUDOERS})"

{
	echo "Defaults:${VAGRANT_USER} !requiretty"
	echo '#Defaults !visiblepw'
	echo 'Defaults env_keep += "SSH_AUTH_SOCK"'
	echo "${VAGRANT_USER} ALL=(ALL) NOPASSWD: ALL"
} >> "${SUDOERS}"

chmod 0440 "${SUDOERS}"

mkdir -p "${DOT_SSH}"

curl -o "${DOT_SSH}/vagrant" "${KEYS_URL}/vagrant"
curl -o "${DOT_SSH}/vagrant.pub" "${KEYS_URL}/vagrant.pub"

cat "${DOT_SSH}/vagrant.pub" >> "${DOT_SSH}/authorized_keys"

chown -R "${VAGRANT_USER}":"${VAGRANT_USER}" "${DOT_SSH}"
chmod 0700 "${DOT_SSH}"
chmod 0640 "${DOT_SSH}/authorized_keys" "${DOT_SSH}/vagrant.pub"
chmod 0600 "${DOT_SSH}/vagrant"

