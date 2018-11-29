#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

function lts-kernel() {
  echo "defaulting to LTS kernel"
  swupd bundle-add kernel-lts
  lts="$(clr-boot-manager list-kernels | grep lts)"
  clr-boot-manager set-kernel ${lts}
  swupd bundle-remove kernel-native
}

case "${PACKER_BUILDER_TYPE}" in
  vmware-vmx)
    echo "VMware detected..."
    swupd bundle-add os-cloudguest-vmware
    systemctl enable open-vm-tools
    lts-kernel
  ;;
  virtualbox-ovf)
    echo "VirtualBox detected..."
    lts-kernel
  ;;
  qemu)
    echo "qemu/kvm detected..."
    echo
  ;;
esac
