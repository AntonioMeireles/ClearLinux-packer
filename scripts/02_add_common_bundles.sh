#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

systemctl start boot.mount

swupd bundle-add sysadmin-basic network-basic vim shells containers-basic patch diffutils
systemctl enable docker

