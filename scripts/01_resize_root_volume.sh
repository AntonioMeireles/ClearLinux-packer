#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

swupd bundle-add storage-utils

if [[ "${PACKER_BUILDER_TYPE}" == "qemu" ]]; then
  ROOT_DEVICE=/dev/vda
else
  ROOT_DEVICE=/dev/sda
fi

MAXSIZEMB=$(printf %s\\n 'unit MB print list' | parted | grep "Disk ${ROOT_DEVICE}" | cut -d' ' -f3 | tr -d MB)
echo -e "F\\n3\\n${MAXSIZEMB}MB\\n" | parted "${ROOT_DEVICE}" ---pretend-input-tty resizepart
partprobe ${ROOT_DEVICE}
resize2fs ${ROOT_DEVICE}3

swupd bundle-remove storage-utils

