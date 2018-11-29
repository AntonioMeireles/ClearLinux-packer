#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

if [[ "${PACKER_BUILDER_TYPE}" != "qemu" ]]; then
    echo '- Zeroing out empty space for better compressability'
    # /
    dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
    rm -f /EMPTY

    systemctl start boot.mount
    # /boot
    dd if=/dev/zero of=/boot/EMPTY bs=1M || echo "dd exit code $? is suppressed"
    rm -f /boot/EMPTY
    systemctl stop boot.mount

    set +e
    swapuuid="$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)"
    set -e
    if [[ "x${swapuuid}" != "x" ]]; then
        # zeroes swap partition to reduce box size, Swap disabled till reboot
        swappart="$(readlink -f /dev/disk/by-uuid/${swapuuid})"
        /sbin/swapoff "${swappart}"
        dd if=/dev/zero of="${swappart}" bs=1M || echo "dd exit code $? is suppressed"
        /sbin/mkswap -U "${swapuuid}" "${swappart}"
    fi
    sync
fi

