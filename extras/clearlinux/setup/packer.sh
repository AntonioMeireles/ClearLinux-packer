#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

PACKER_VERSION=1.6.6

GOPATH="$(mktemp -d)"
BUILDPATH="$(mktemp -d)"
GO111MODULE=auto
BUILDPATCH="$(cd `dirname $0` && pwd)/justNativePackerBuild.patch"

export PACKER_VERSION
export GOPATH
export GO111MODULE
export BUILDPATH
export BUILDPATCH

function cleanup() {
  sudo rm -rf "${GOPATH}"
  sudo rm -rf "${BUILDPATH}"
}

trap cleanup EXIT

sudo swupd bundle-add {c,ruby,go}-basic git

git clone https://github.com/hashicorp/packer "${BUILDPATH}"

pushd "${BUILDPATH}"
git checkout "v${PACKER_VERSION}"
patch -p1 < "${BUILDPATCH}"
make releasebin
sudo install -Dm0755 "${GOPATH}/bin/packer" /usr/local/bin
