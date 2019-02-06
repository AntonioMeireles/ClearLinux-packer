#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace
set +e

echo '- Zeroing out empty space for better compressability'
swapuuid="$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)"
if [[ "x${swapuuid}" != "x" ]]; then
    # zeroes swap partition to reduce box size, Swap disabled till reboot
    swappart=$(readlink -f /dev/disk/by-uuid/"${swapuuid}")
    /sbin/swapoff "${swappart}"
    dd if=/dev/zero of="${swappart}" bs=1M || echo "dd exit code $? is suppressed"
    /sbin/mkswap -U "${swapuuid}" "${swappart}"
fi

# /
dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
rm -f /EMPTY

# /boot
dd if=/dev/zero of=/boot/EMPTY bs=1M || echo "dd exit code $? is suppressed"
rm -f /boot/EMPTY

sync



