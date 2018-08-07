#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

swupd clean

echo '- Zeroing out empty space for better compressability'
dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
rm -f /EMPTY
sync
