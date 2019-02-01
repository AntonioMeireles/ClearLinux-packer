#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

systemctl start boot.mount

swupd bundle-add sysadmin-basic network-basic vim shells containers-basic patch diffutils
# We are not enabling docker by default as it is not required for all
# use-cases. Kindly enable the docker service if you wish to use it.
