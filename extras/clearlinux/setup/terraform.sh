#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

export TERRAFORM_VERSION=0.14.9
export TERRAFORM_PROVIDER_LIBVIRT_VERSION=0.6.3

export TERRAFORM_URL=https://github.com/hashicorp/terraform/archive/v${TERRAFORM_VERSION}.zip

export LIBVIRT_PLUGIN_DIR=~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/${TERRAFORM_PROVIDER_LIBVIRT_VERSION}/linux_amd64
export LIBVIRT_PLUGIN_NAME=terraform-provider-libvirt

export BINDIR=/usr/local/bin/

GOPATH="$(mktemp -d)"
export GOPATH
export GO111MODULE=on

zipfile="$(mktemp)"
export zipfile

source_dir="/tmp/terraform-${TERRAFORM_VERSION}"
export source_dir

function cleanup() {
  sudo rm -rf "${source_dir}" "${GOPATH}" "${zipfile}"
}

trap cleanup EXIT

sudo swupd bundle-add {c,go}-basic xorriso zip

curl -sL ${TERRAFORM_URL} -o "${zipfile}"
unzip -qq "${zipfile}" -d /tmp

pushd ${source_dir}
  export PATH="${GOPATH}/bin:${PATH}"
  export XC_OS="linux"
  export XC_ARCH="amd64"

  ./scripts/build.sh
  sudo install -Dvm0755 "${GOPATH}/bin/terraform" -t ${BINDIR}

  go get github.com/dmacvicar/${LIBVIRT_PLUGIN_NAME}@v${TERRAFORM_PROVIDER_LIBVIRT_VERSION}
  install -Dvm0755 "${GOPATH}/bin/${LIBVIRT_PLUGIN_NAME}" ${LIBVIRT_PLUGIN_DIR}/${LIBVIRT_PLUGIN_NAME}
popd


