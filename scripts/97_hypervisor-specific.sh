#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

function lts-kernel() {
  echo "defaulting to LTS kernel"
  swupd bundle-add kernel-lts
  lts="$(clr-boot-manager list-kernels | grep lts | sed -e 's/ //g')"
  clr-boot-manager set-kernel "${lts}"
  case "${PACKER_BUILDER_TYPE}" in
    qemu)
      swupd bundle-remove kernel-kvm
    ;;
    *)
      swupd bundle-remove kernel-native
    ;;
  esac
}

# doesn't make much sense in this context ...
# upstream should tweak it so that it only runs in non virtualized environments
systemctl mask clr-power

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
    lts-kernel
  ;;
esac
