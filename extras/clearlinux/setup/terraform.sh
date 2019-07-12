#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

export TERRAFORM_PLUGIN_DIR=~/.terraform.d/plugins
export TERRAFORM_VERSION=0.12.4
export TERRAFORM_PROVIDER_LIBVIRT_VERSION=0.5.2
GOPATH="$(mktemp -d)"
export GOPATH
export GO111MODULE=on

function cleanup() {
  sudo rm -rf "${GOPATH}"
}

trap cleanup EXIT

sudo swupd bundle-add {c,go}-basic xorriso

go get github.com/hashicorp/terraform@v${TERRAFORM_VERSION}
sudo install -Dvm0755 "${GOPATH}/bin/terraform" -t /usr/local/bin/

go get github.com/dmacvicar/terraform-provider-libvirt@v${TERRAFORM_PROVIDER_LIBVIRT_VERSION}
install -Dvm0755 "${GOPATH}/bin/terraform-provider-libvirt" ${TERRAFORM_PLUGIN_DIR}/terraform-provider-libvirt
