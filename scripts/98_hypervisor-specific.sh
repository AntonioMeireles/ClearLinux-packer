#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

HYPERVISOR="$(systemd-detect-virt -v)"

case "${HYPERVISOR}" in
	'vmware')
		echo "VMware detected..."
		swupd bundle-add os-cloudguest-vmware
		systemctl enable open-vm-tools
	;;
	'oracle')
	echo "VirtualBox detected..."
		swupd bundle-add kernel-lts
		swupd bundle-remove kernel-native
		mount /dev/sda1 /boot
		echo 'default '$(ls /boot/loader/entries/ | grep lts | sed -e 's/.conf$//') > /boot/loader/loader.conf
		rm -rfv /boot/*/*/*native*
		umount /boot
	;;
esac
