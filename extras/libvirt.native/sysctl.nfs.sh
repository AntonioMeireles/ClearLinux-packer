#!/usr/bin/env bash
# shellcheck source=/dev/null

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

export SYSCTLDIR=/etc/sysctl.d

mkdir -p ${SYSCTLDIR}

{
  echo vm.max_map_count = 262144
  echo fs.file-max = 801896
  echo net.core.somaxconn = 65535
  echo
} > ${SYSCTLDIR}/99-nfs.conf

systemctl restart systemd-sysctl
