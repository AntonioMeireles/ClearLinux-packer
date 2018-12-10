#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

echo '- Zeroing out empty space for better compressability'
systemctl start boot.mount
if [[ "${PACKER_BUILDER_TYPE}" == "qemu" ]]; then
    fstrim -av
    systemctl enable fstrim.timer
else
    # /
    dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
    rm -f /EMPTY

    # /boot
    dd if=/dev/zero of=/boot/EMPTY bs=1M || echo "dd exit code $? is suppressed"
    rm -f /boot/EMPTY

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
fi
systemctl stop boot.mount
sync



