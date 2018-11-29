#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

swupd bundle-add storage-utils

case "${PACKER_BUILDER_TYPE}" in
  qemu)
    ROOT_DEVICE=/dev/vda
  ;;
  *)
    ROOT_DEVICE=/dev/sda
  ;;
esac

MAXSIZEMB=$(printf %s\\n 'unit MB print list' | parted | grep "Disk ${ROOT_DEVICE}" | cut -d' ' -f3 | tr -d MB)
echo -e "F\\n3\\n${MAXSIZEMB}MB\\n" | parted "${ROOT_DEVICE}" ---pretend-input-tty resizepart
partprobe ${ROOT_DEVICE}
resize2fs ${ROOT_DEVICE}3
