#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

sudo swupd bundle-add {c,ruby,go}-basic devpkg-lib{virt,xml2,xslt,gpg-error} libarchive

VAGRANT_VERSION=2.2.4
VAGRANT_ZIP="v${VAGRANT_VERSION}.zip"
VAGRANT_URL=https://github.com/hashicorp/vagrant/archive/${VAGRANT_ZIP}

EMBEDDED_DIR=/opt/vagrant/embedded

zipfile=/tmp/${VAGRANT_ZIP}
rm -rf ${zipfile} || true
curl -sL ${VAGRANT_URL} -o ${zipfile}
(cd /tmp ; unzip -qq ${zipfile} && rm -rf ${zipfile})

source_dir="/tmp/vagrant-${VAGRANT_VERSION}"

pushd ${source_dir}
  git clone https://github.com/hashicorp/vagrant-installers || true
  substrate_dir="${source_dir}/vagrant-installers/substrate"
  gem build vagrant.gemspec

  pushd "${substrate_dir}/launcher"
    go get github.com/mitchellh/osext
    go build -o vagrant
  popd

  sudo install -Dm644 "${substrate_dir}/common/gemrc" "${EMBEDDED_DIR}/etc/gemrc"

  sudo mkdir -p ${EMBEDDED_DIR}/rgloader/
  sudo install -m644 ${substrate_dir}/{linux,common}/rgloader/* "${EMBEDDED_DIR}/rgloader/"

  export GEM_PATH="${EMBEDDED_DIR}/gems/${VAGRANT_VERSION}"
  export GEM_HOME="${GEM_PATH}"
  export GEMRC="${EMBEDDED_DIR}/etc/gemrc"
  # XXX
  # export NOKOGIRI_USE_SYSTEM_LIBRARIES

  sudo mkdir -p ${GEM_PATH}

  sudo -E gem install pkg-config --no-document
  sudo -E gem install vagrant-${VAGRANT_VERSION}.gem --no-document
  # XXX until building with system libs is sorted we need to install it before
  # attempting agrant plugin install vagrant-libvirt
  sudo -E gem install nokogiri --no-document

  sudo install -Dm755 "${substrate_dir}/launcher/vagrant" /opt/vagrant/bin/vagrant

  sudo ln -sf /opt/vagrant/bin/vagrant /usr/local/bin/

  [[ -f ${EMBEDDED_DIR}/manifest.json ]] || \
    echo '{"vagrant_version": "'${VAGRANT_VERSION}'"}' | sudo tee ${EMBEDDED_DIR}/manifest.json
  [[ -f ${EMBEDDED_DIR}/plugins.json ]] || \
    echo '{"version":"1","installed":{}}' | sudo tee ${EMBEDDED_DIR}/plugins.json
  sudo chmod 644 ${EMBEDDED_DIR}/*.json
  vagrant plugin install vagrant-libvirt vagrant-guests-clearlinux

  rm -rf ${source_dir}
popd