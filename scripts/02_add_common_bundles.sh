#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

systemctl start boot.mount

swupd bundle-add sysadmin-basic network-basic vim shells containers-basic patch diffutils
# We are not activating docker by default as it is not required for all
# use-cases. `sudo systemctl unmask docker.service` if you wish to use it.
systemctl mask docker
