#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

swupd bundle-add sysadmin-basic network-basic vim shells containers-basic patch diffutils
systemctl enable docker

