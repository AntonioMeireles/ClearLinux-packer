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
lts="$(clr-boot-manager list-kernels | grep lts)"
clr-boot-manager set-kernel ${lts}
swupd bundle-remove kernel-native
