#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

export PACKER_VERSION=1.4.3

GOPATH="$(mktemp -d)"
export GOPATH
export GO111MODULE=on

function cleanup() {
  sudo rm -rf "${GOPATH}"
}

trap cleanup EXIT

sudo swupd bundle-add {c,ruby,go}-basic

go get github.com/hashicorp/packer@v${PACKER_VERSION}

sudo install -Dm0755 "${GOPATH}/bin/packer" /usr/local/bin
