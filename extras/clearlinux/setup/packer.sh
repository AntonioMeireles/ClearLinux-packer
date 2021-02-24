#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

PACKER_VERSION=1.7.0

GOPATH="$(mktemp -d)"
BUILDPATH="$(mktemp -d)"
GO111MODULE=auto

export PACKER_VERSION
export GOPATH
export GO111MODULE
export BUILDPATH

function cleanup() {
  sudo rm -rf "${GOPATH}"
  sudo rm -rf "${BUILDPATH}"
}

trap cleanup EXIT

sudo swupd bundle-add {c,ruby,go}-basic git

git clone https://github.com/hashicorp/packer "${BUILDPATH}"

pushd "${BUILDPATH}"
git checkout "v${PACKER_VERSION}"

sed -i 's/^ALL_XC_ARCH=.*/ALL_XC_ARCH="amd64"/' scripts/build.sh
sed -i 's/^ALL_XC_OS=.*/ALL_XC_OS="linux"/' scripts/build.sh

make releasebin
sudo install -Dm0755 "${GOPATH}/bin/packer" /usr/local/bin
