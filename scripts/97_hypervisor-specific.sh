#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

HYPERVISOR="$(systemd-detect-virt -v)"

case "${HYPERVISOR}" in
  vmware)
    echo "VMware detected..."
    swupd bundle-add os-cloudguest-vmware
    systemctl enable open-vm-tools
  ;;
  oracle)
    echo "VirtualBox detected..."
    echo
  ;;
esac

echo "defaulting to LTS kernel"
swupd bundle-add kernel-lts
swupd bundle-remove kernel-native
systemctl start boot.mount
echo 'default '$(ls /boot/loader/entries/ | grep lts | sed -e 's/.conf$//') > /boot/loader/loader.conf
rm -rfv /boot/*/*/*native*
systemctl stop boot.mount
