#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

revision=$(swupd info | grep Installed | sed -e 's/.*: //')
if [[ "${revision}" -lt 29090 ]]; then
  echo "Aborted: this requires Clear Linux version '29090' or later - you're running '${revision}'"
  echo "         please run 'sudo swupd update' first"
  exit 1
fi
# 'libarchive' is a much needed runtime dep as it provides 'bsdtar' which is
# used to unpack boxes
sudo swupd bundle-add {c,ruby,go}-basic devpkg-lib{virt,xml2,xslt,gpg-error,gcrypt} libarchive

VAGRANT_VERSION=2.2.18
VAGRANT_ZIP="v${VAGRANT_VERSION}.zip"
VAGRANT_URL=https://github.com/hashicorp/vagrant/archive/${VAGRANT_ZIP}

EMBEDDED_DIR=/opt/vagrant/embedded

GOPATH=$(mktemp -d)
export GOPATH

zipfile="$(mktemp)"
curl -sL ${VAGRANT_URL} -o "${zipfile}"
unzip -qq "${zipfile}" -d /tmp

source_dir="/tmp/vagrant-${VAGRANT_VERSION}"

function cleanup() {
  sudo rm -rf ${source_dir} "${GOPATH}" "${zipfile}"
}

trap cleanup EXIT

pushd ${source_dir}
  git clone https://github.com/hashicorp/vagrant-installers
  substrate_dir="${source_dir}/vagrant-installers/substrate"

  pushd "${substrate_dir}/launcher"
    go get github.com/mitchellh/osext
    go build -o vagrant
  popd

  export GEMRC="${EMBEDDED_DIR}/etc/gemrc"
  export GEM_PATH="${EMBEDDED_DIR}/gems/${VAGRANT_VERSION}"
  export GEM_HOME="${GEM_PATH}"

  sudo install -D -m 0644 ${substrate_dir}/common/gemrc "${GEMRC}"
  sudo mkdir -p ${GEM_PATH}

  gem build vagrant.gemspec

  sudo -E gem install pkg-config vagrant-${VAGRANT_VERSION}.gem --no-document --prerelease
  # workaround for gems dep resolution woes
  sudo sed -i 's/>= 2.6.5/>= 6.2.0.rc2/g' "${GEM_PATH}/specifications/net-scp-3.0.0.gemspec"

  sudo rm -rf ${GEM_PATH}/gems/vagrant-${VAGRANT_VERSION}/vagrant-installers

  sudo install -D -m 0755 "${substrate_dir}/launcher/vagrant" /opt/vagrant/bin/vagrant
  sudo ln -sf /opt/vagrant/bin/vagrant /usr/local/bin/

  echo '{"vagrant_version": "'${VAGRANT_VERSION}'"}' | sudo tee ${EMBEDDED_DIR}/manifest.json
  echo '{"version":"1","installed":{}}' | sudo tee ${EMBEDDED_DIR}/plugins.json
  sudo chmod 0644 ${EMBEDDED_DIR}/*.json

  export CFLAGS="-I/usr/include/ruby-3.0.0/ruby/"
  # for some reason getting transient breakage if installing more than one plugin at once (!)...
  vagrant plugin install vagrant-libvirt
  vagrant plugin install vagrant-guests-clearlinux

popd

